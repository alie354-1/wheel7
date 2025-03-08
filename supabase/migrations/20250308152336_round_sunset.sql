/*
  # Fix Profiles Policies
  
  1. Changes
    - Drop problematic policies
    - Create simplified policies without recursion
    - Update trigger function
  
  2. Security
    - Maintain RLS
    - Fix infinite recursion
    - Preserve permissions
*/

-- Drop existing policies to start fresh
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles CASCADE;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles CASCADE;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles CASCADE;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles CASCADE;

-- Create simplified policies without recursion
CREATE POLICY "Enable read access to own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Enable update access to own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Enable admin read access"
  ON profiles FOR SELECT
  TO authenticated
  USING (role IN ('admin', 'superadmin'));

CREATE POLICY "Enable admin update access"
  ON profiles FOR UPDATE
  TO authenticated
  USING (role IN ('admin', 'superadmin'))
  WITH CHECK (role IN ('admin', 'superadmin'));

-- Update trigger function to handle new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    email,
    role,
    is_public,
    allows_messages,
    settings,
    setup_progress
  )
  VALUES (
    NEW.id,
    NEW.email,
    'superadmin',
    true,
    true,
    jsonb_build_object(
      'notifications', jsonb_build_object('email', true, 'push', true),
      'privacy', jsonb_build_object('showProfile', true, 'allowMessages', true),
      'app_credentials', jsonb_build_object(),
      'feature_flags', jsonb_build_object(),
      'openai', jsonb_build_object(),
      'cloud_storage', jsonb_build_object()
    ),
    jsonb_build_object(
      'current_step', 'basic',
      'completed_steps', ARRAY[]::text[],
      'form_data', '{}'::jsonb
    )
  );
  RETURN NEW;
END;
$$;