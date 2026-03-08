-- Migration for Admin Panel in Flutter App

-- 1. Add is_admin column to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- 2. Update RLS Policies to allow Admins to read/write specific tables

-- A. Subscriptions
DROP POLICY IF EXISTS "Admins can view all subscriptions" ON subscriptions;
CREATE POLICY "Admins can view all subscriptions" ON subscriptions FOR SELECT
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE));

DROP POLICY IF EXISTS "Admins can update all subscriptions" ON subscriptions;
CREATE POLICY "Admins can update all subscriptions" ON subscriptions FOR UPDATE
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE));

-- B. Payment Requests
DROP POLICY IF EXISTS "Admins can view all requests" ON payment_requests;
CREATE POLICY "Admins can view all requests" ON payment_requests FOR SELECT
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE));

DROP POLICY IF EXISTS "Admins can update all requests" ON payment_requests;
CREATE POLICY "Admins can update all requests" ON payment_requests FOR UPDATE
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE));

-- C. Profiles
-- Secure function to check admin without causing infinite recursion
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

DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Admins can view all profiles" ON profiles FOR SELECT
USING (public.is_app_admin());

-- D. App Config
DROP POLICY IF EXISTS "Admins can update app config" ON app_config;
CREATE POLICY "Admins can update app config" ON app_config FOR UPDATE
USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE));

-- 3. Storage Policy (so admin can view receipts)
-- Previously created: "Admins can view all" for service_role. Now we need for admin user.
DROP POLICY IF EXISTS "Flutter Admins can view all receipts" ON storage.objects;
CREATE POLICY "Flutter Admins can view all receipts"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'payment_receipts' AND 
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = TRUE)
);

-- How to make someone an admin? 
-- Run this manually once:
-- UPDATE public.profiles SET is_admin = TRUE WHERE id = 'YOUR_USER_ID';
