-- Script to add "Activate by Days" functionality and Fix RLS

-- 1. Create a function to activate subscription by custom days using Customer ID (first 8 chars of user ID)
CREATE OR REPLACE FUNCTION activate_subscription_by_days(
    p_customer_id TEXT, 
    p_days INTEGER, 
    p_admin_id UUID
) 
RETURNS void AS $$ 
DECLARE 
    v_user_id UUID; 
BEGIN 
    -- Find the user matching the short customer ID (like 'A1B2C3D4%')
    SELECT id INTO v_user_id 
    FROM public.profiles 
    WHERE upper(id::text) LIKE upper(p_customer_id || '%') 
    LIMIT 1; 

    IF v_user_id IS NULL THEN 
        RAISE EXCEPTION 'المستخدم غير موجود'; 
    END IF; 

    -- Upsert the subscription
    INSERT INTO public.subscriptions (user_id, plan_type, status, start_date, end_date, activated_by, activated_at) 
    VALUES (
        v_user_id, 
        'monthly', 
        'active', 
        NOW(), 
        NOW() + (p_days || ' days')::interval, 
        p_admin_id, 
        NOW()
    ) 
    ON CONFLICT (user_id) DO UPDATE SET 
        status = 'active', 
        start_date = NOW(), 
        end_date = NOW() + (p_days || ' days')::interval, 
        activated_by = EXCLUDED.activated_by, 
        activated_at = EXCLUDED.activated_at; 

    -- Send notification
    INSERT INTO public.notifications (user_id, title, body, type) 
    VALUES (
        v_user_id, 
        'تم التمديد', 
        'تم تفعيل حسابك لمدة ' || p_days || ' يوم بنجاح.', 
        'activation'
    ); 
END; 
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2. Fix Admin RLS properly using a secure function to prevent infinite recursion
CREATE OR REPLACE FUNCTION public.is_app_admin() 
RETURNS BOOLEAN AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  SELECT is_admin INTO v_is_admin 
  FROM public.profiles 
  WHERE id = auth.uid() 
  LIMIT 1;
  RETURN COALESCE(v_is_admin, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop the old policy that caused recursion
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;

-- Create the new safe policy
CREATE POLICY "Admins can view all profiles" ON profiles FOR SELECT
USING (public.is_app_admin());
