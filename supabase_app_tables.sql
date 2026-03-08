-- ===================================================
-- App Data Tables for دفتري (Daftari)
-- Run this in Supabase SQL Editor
-- ===================================================

-- PRODUCTS TABLE
CREATE TABLE IF NOT EXISTS public.user_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    unit TEXT NOT NULL DEFAULT 'قطعة',
    barcode TEXT,
    retail_price NUMERIC(12, 2) NOT NULL DEFAULT 0,
    wholesale_price NUMERIC(12, 2),
    stock NUMERIC(12, 3),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.user_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users own their products" ON user_products;
CREATE POLICY "Users own their products" ON user_products
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- CUSTOMERS TABLE
CREATE TABLE IF NOT EXISTS public.user_customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    total_debt NUMERIC(12, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.user_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users own their customers" ON user_customers;
CREATE POLICY "Users own their customers" ON user_customers
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- INVOICES TABLE
CREATE TABLE IF NOT EXISTS public.user_invoices (
    id TEXT PRIMARY KEY,            -- e.g. INV-001
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    num INTEGER NOT NULL,
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    customer_id UUID REFERENCES public.user_customers(id) ON DELETE SET NULL,
    customer_name TEXT NOT NULL,
    customer_phone TEXT,
    subtotal NUMERIC(12, 2) NOT NULL DEFAULT 0,
    discount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    grand_total NUMERIC(12, 2) NOT NULL DEFAULT 0,
    paid NUMERIC(12, 2) NOT NULL DEFAULT 0,
    debt NUMERIC(12, 2) NOT NULL DEFAULT 0,
    pay_type TEXT NOT NULL DEFAULT 'cash',   -- cash / partial / debt / تسديد دين
    note TEXT,
    status TEXT NOT NULL DEFAULT 'paid',     -- paid / partial / unpaid
    shop_name TEXT NOT NULL DEFAULT '',
    shop_logo_path TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, num)
);
ALTER TABLE public.user_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users own their invoices" ON user_invoices;
CREATE POLICY "Users own their invoices" ON user_invoices
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- INVOICE ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.user_invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id TEXT NOT NULL REFERENCES public.user_invoices(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_name TEXT NOT NULL,
    unit TEXT NOT NULL DEFAULT 'قطعة',
    qty NUMERIC(12, 3) NOT NULL DEFAULT 1,
    unit_price NUMERIC(12, 2) NOT NULL DEFAULT 0,
    price_type TEXT NOT NULL DEFAULT 'retail',  -- retail / wholesale
    total NUMERIC(12, 2) NOT NULL DEFAULT 0
);
ALTER TABLE public.user_invoice_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users own their invoice items" ON user_invoice_items;
CREATE POLICY "Users own their invoice items" ON user_invoice_items
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Admins can view all app data
DROP POLICY IF EXISTS "Admins can view all products" ON user_products;
CREATE POLICY "Admins can view all products" ON user_products FOR SELECT USING (public.is_app_admin());
DROP POLICY IF EXISTS "Admins can view all customers" ON user_customers;
CREATE POLICY "Admins can view all customers" ON user_customers FOR SELECT USING (public.is_app_admin());
DROP POLICY IF EXISTS "Admins can view all invoices" ON user_invoices;
CREATE POLICY "Admins can view all invoices" ON user_invoices FOR SELECT USING (public.is_app_admin());
