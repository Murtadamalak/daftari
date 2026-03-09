-- Migration for 'مدير الديون' (Debt Manager)
-- Technology: Flutter + Supabase

-- 1. Custom Enums
CREATE TYPE plan_type AS ENUM ('free', 'monthly', 'yearly');
CREATE TYPE subscription_status AS ENUM ('active', 'expired', 'pending', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE notification_type AS ENUM ('activation', 'expiry_warning', 'rejection');

-- 2. Profiles Table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT,
    shop_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Subscriptions Table
CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_type plan_type NOT NULL DEFAULT 'free',
    status subscription_status NOT NULL DEFAULT 'active',
    start_date TIMESTAMPTZ DEFAULT NOW(),
    end_date TIMESTAMPTZ, -- NULL for free tier or managed manually
    activated_by UUID REFERENCES auth.users(id), -- Admin who activated it
    activated_at TIMESTAMPTZ,
    notes TEXT,
    UNIQUE(user_id) -- One active record per user for simplicity
);

-- 4. Payment Requests Table (Manual Transfer Proofs)
CREATE TABLE public.payment_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_type plan_type NOT NULL,
    amount NUMERIC(10, 2) NOT NULL, -- e.g. 5000 or 40000
    transfer_number TEXT, -- Reference number from Zain Cash or similar
    receipt_url TEXT, -- Path in Supabase Storage
    status payment_status NOT NULL DEFAULT 'pending',
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES auth.users(id),
    rejection_reason TEXT
);

-- 5. Notifications Table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE, -- NULL if global or for all admins
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    type notification_type NOT NULL,
    is_for_admin BOOLEAN DEFAULT FALSE, -- To differentiate admin notifications
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. App Config Table
CREATE TABLE public.app_config (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Initial Config Seed
INSERT INTO public.app_config (key, value) VALUES 
('payment_info', '{"zain_cash_number": "07700000000", "account_holder": "اسم صاحب الحساب"}'),
('pricing', '{"monthly": 10000, "yearly": 99000}'),
('welcome_message', '{"title": "أهلاً بك!", "body": "شكراً لاستخدامك تطبيق مدير الديون."}');

-- 7. Free Tier Usage Table
CREATE TABLE public.free_tier_usage (
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    month_year TEXT NOT NULL, -- Format 'YYYY-MM'
    invoice_count INTEGER DEFAULT 0,
    customer_count INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, month_year)
);

-- ==========================================
-- RLS POLICIES (Row Level Security)
-- ==========================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.free_tier_usage ENABLE ROW LEVEL SECURITY;

-- 1. User can read/update their own profile
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- 2. User can read their own subscription
CREATE POLICY "Users can view own subscription" ON subscriptions FOR SELECT USING (auth.uid() = user_id);

-- 3. User can manage their own payment requests
CREATE POLICY "Users can view own payment requests" ON payment_requests FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own payment requests" ON payment_requests FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 4. User can read/update their own notifications
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- 5. App config is readable by everyone, writable by service_role (Admin)
CREATE POLICY "Config is readable by everyone" ON app_config FOR SELECT TO authenticated USING (true);

-- 6. Free tier usage
CREATE POLICY "Users can view own usage" ON free_tier_usage FOR SELECT USING (auth.uid() = user_id);

-- ==========================================
-- FUNCTIONS & TRIGGERS
-- ==========================================

-- A. Auto-create Profile on Signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone, shop_name)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'phone', new.raw_user_meta_data->>'shop_name');
  
  -- Create initial FREE subscription
  INSERT INTO public.subscriptions (user_id, plan_type, status)
  VALUES (new.id, 'free', 'active');
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- B. Trigger: Expire subscription if end_date exceeded
CREATE OR REPLACE FUNCTION public.check_subscription_expiry()
RETURNS trigger AS $$
BEGIN
  IF NEW.end_date IS NOT NULL AND NEW.end_date < NOW() THEN
    NEW.status = 'expired';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_expiry
  BEFORE INSERT OR UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.check_subscription_expiry();

-- C. Trigger: Notify Admin on new payment request
CREATE OR REPLACE FUNCTION public.on_payment_request_submitted()
RETURNS trigger AS $$
DECLARE
    v_user_name TEXT;
BEGIN
    SELECT full_name INTO v_user_name FROM public.profiles WHERE id = NEW.user_id;

    -- Notification for the user
    INSERT INTO public.notifications (user_id, title, body, type)
    VALUES (
        NEW.user_id,
        'طلب الدفع قيد المراجعة',
        'لقد تم استلام طلب تفعيل الباقة ' || NEW.plan_type || ' وسيتم مراجعته قريباً.',
        'activation'
    );

    -- Notification for the Admin
    INSERT INTO public.notifications (user_id, title, body, type, is_for_admin)
    VALUES (
        NULL, -- No specific user_id for admin global notifications
        'طلب دفع جديد من ' || COALESCE(v_user_name, 'مستخدم'),
        'قام المستخدم برفع وصل لباقة ' || NEW.plan_type || '. يرجى المراجعة.',
        'activation',
        TRUE
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_payment_submitted
  AFTER INSERT ON public.payment_requests
  FOR EACH ROW EXECUTE FUNCTION public.on_payment_request_submitted();

-- D. Function: get_user_subscription_status
CREATE OR REPLACE FUNCTION get_user_subscription_status(target_user_id UUID)
RETURNS TABLE (
    plan plan_type,
    current_status subscription_status,
    days_remaining INTEGER,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.plan_type,
        s.status,
        CASE 
            WHEN s.plan_type = 'free' THEN 9999 -- Infinite for free
            WHEN s.end_date IS NULL THEN 0
            ELSE EXTRACT(DAY FROM (s.end_date - NOW()))::INTEGER
        END as days_remaining,
        (s.status = 'active' AND (s.end_date IS NULL OR s.end_date > NOW())) as is_active
    FROM public.subscriptions s
    WHERE s.user_id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- E. Function: activate_subscription (Admin Action)
CREATE OR REPLACE FUNCTION activate_subscription(
    p_user_id UUID,
    p_plan plan_type,
    p_admin_id UUID,
    p_payment_request_id UUID DEFAULT NULL
)
RETURNS void AS $$
DECLARE
    v_duration INTERVAL;
BEGIN
    IF p_plan = 'monthly' THEN
        v_duration := INTERVAL '1 month';
    ELSIF p_plan = 'yearly' THEN
        v_duration := INTERVAL '1 year';
    ELSE
        v_duration := INTERVAL '0 days';
    END IF;

    -- 1. Update/Upsert Subscription
    INSERT INTO public.subscriptions (user_id, plan_type, status, start_date, end_date, activated_by, activated_at)
    VALUES (
        p_user_id, 
        p_plan, 
        'active', 
        NOW(), 
        NOW() + v_duration, 
        p_admin_id, 
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        plan_type = EXCLUDED.plan_type,
        status = 'active',
        start_date = NOW(),
        end_date = NOW() + v_duration,
        activated_by = EXCLUDED.activated_by,
        activated_at = EXCLUDED.activated_at;

    -- 2. Update Payment Request if exists
    IF p_payment_request_id IS NOT NULL THEN
        UPDATE public.payment_requests
        SET status = 'approved', reviewed_at = NOW(), reviewed_by = p_admin_id
        WHERE id = p_payment_request_id;
    END IF;

    -- 3. Notify User
    INSERT INTO public.notifications (user_id, title, body, type)
    VALUES (
        p_user_id,
        'تم تفعيل الاشتراك بنجاح',
        'تم تفعيل باقتك ال' || p_plan || ' بنجاح. شكراً لثقتك بنا.',
        'activation'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- F. Function: check_free_limit
CREATE OR REPLACE FUNCTION check_free_limit(p_user_id UUID, p_action_type TEXT)
RETURNS JSONB AS $$
DECLARE
    v_plan plan_type;
    v_month_year TEXT;
    v_usage_count INTEGER;
    v_limit INTEGER;
    v_allowed BOOLEAN;
BEGIN
    -- Get current plan
    SELECT plan_type INTO v_plan FROM public.subscriptions WHERE user_id = p_user_id;
    
    -- If not free, it's unlimited (or high limit)
    IF v_plan != 'free' THEN
        RETURN jsonb_build_object('allowed', true, 'remaining', 999, 'limit', 999);
    END IF;

    v_month_year := to_char(NOW(), 'YYYY-MM');
    
    -- Initialize usage for new month if not exists
    INSERT INTO public.free_tier_usage (user_id, month_year, invoice_count, customer_count)
    VALUES (p_user_id, v_month_year, 0, 0)
    ON CONFLICT (user_id, month_year) DO NOTHING;

    IF p_action_type = 'customer' THEN
        v_limit := 10;
        SELECT customer_count INTO v_usage_count FROM public.free_tier_usage 
        WHERE user_id = p_user_id AND month_year = v_month_year;
    ELSIF p_action_type = 'invoice' THEN
        v_limit := 20;
        SELECT invoice_count INTO v_usage_count FROM public.free_tier_usage 
        WHERE user_id = p_user_id AND month_year = v_month_year;
    ELSE
        v_limit := 0;
        v_usage_count := 0;
    END IF;

    v_allowed := v_usage_count < v_limit;
    
    RETURN jsonb_build_object(
        'allowed', v_allowed,
        'remaining', GREATEST(0, v_limit - v_usage_count),
        'limit', v_limit
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- STORAGE POLICIES
-- ==========================================
-- (Must be run after creating the bucket manually or via API)
-- Bucket: payment_receipts

/*
-- Create bucket (Run this in the Supabase UI or via an Admin client)
-- INSERT INTO storage.buckets (id, name) VALUES ('payment_receipts', 'payment_receipts');

-- Policies for storage.objects
CREATE POLICY "Users can upload their own receipts"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'payment_receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can view their own receipts"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'payment_receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Admin can view all receipts (via service_role or explicit policy)
CREATE POLICY "Admins can view all"
ON storage.objects FOR SELECT
TO service_role
USING (bucket_id = 'payment_receipts');
*/
