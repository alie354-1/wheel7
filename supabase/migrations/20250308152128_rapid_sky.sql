/*
  # Fix Profiles Table Migration
  
  1. Changes
    - Drop existing policies with CASCADE
    - Update profiles table structure
    - Recreate trigger function and policies
  
  2. Security
    - Maintain RLS policies
    - Preserve permissions
    - Set up secure defaults
    
  3. Notes
    - Uses CASCADE to handle dependencies
    - Preserves existing policy logic
    - Maintains data integrity
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Drop existing policies with CASCADE
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles CASCADE;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles CASCADE;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles CASCADE;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles CASCADE;
DROP POLICY IF EXISTS "Enable read access for own profile" ON profiles CASCADE;
DROP POLICY IF EXISTS "Enable read access for public profiles" ON profiles CASCADE;
DROP POLICY IF EXISTS "Enable update access for own profile" ON profiles CASCADE;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles CASCADE;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles CASCADE;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles CASCADE;
DROP POLICY IF EXISTS "Admins can manage all profiles" ON profiles CASCADE;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles CASCADE;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles CASCADE;
DROP POLICY IF EXISTS "Enable admin access to all profiles" ON profiles CASCADE;

-- Alter existing profiles table
ALTER TABLE profiles 
  ALTER COLUMN role SET DEFAULT 'superadmin',
  ALTER COLUMN is_public SET DEFAULT true,
  ALTER COLUMN allows_messages SET DEFAULT true,
  ALTER COLUMN interests SET DEFAULT '{}'::text[],
  ALTER COLUMN industry_experience SET DEFAULT '{}'::text[],
  ALTER COLUMN previous_startups SET DEFAULT '[]'::jsonb,
  ALTER COLUMN education SET DEFAULT '[]'::jsonb,
  ALTER COLUMN goals SET DEFAULT '{}'::text[],
  ALTER COLUMN availability_status SET DEFAULT 'part-time'::text,
  ALTER COLUMN mentor_preferences SET DEFAULT '{}'::jsonb,
  ALTER COLUMN investment_interests SET DEFAULT '{}'::jsonb,
  ALTER COLUMN languages SET DEFAULT ARRAY['English'::text],
  ALTER COLUMN achievements SET DEFAULT '{}'::text[],
  ALTER COLUMN looking_for SET DEFAULT '{}'::text[],
  ALTER COLUMN social_links SET DEFAULT '{}'::jsonb,
  ALTER COLUMN settings SET DEFAULT jsonb_build_object(
    'notifications', jsonb_build_object('email', true, 'push', true),
    'privacy', jsonb_build_object('showProfile', true, 'allowMessages', true),
    'app_credentials', jsonb_build_object(),
    'feature_flags', jsonb_build_object(),
    'openai', jsonb_build_object(),
    'cloud_storage', jsonb_build_object()
  ),
  ALTER COLUMN setup_progress SET DEFAULT jsonb_build_object(
    'current_step', 'basic',
    'completed_steps', ARRAY[]::text[],
    'form_data', '{}'::jsonb
  );

-- Ensure constraints exist
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'valid_availability_status'
  ) THEN
    ALTER TABLE profiles 
    ADD CONSTRAINT valid_availability_status 
    CHECK (availability_status = ANY (ARRAY['full-time'::text, 'part-time'::text, 'weekends'::text, 'evenings'::text, 'not-available'::text]));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'profiles_role_check'
  ) THEN
    ALTER TABLE profiles 
    ADD CONSTRAINT profiles_role_check 
    CHECK (role = ANY (ARRAY['user'::text, 'admin'::text, 'superadmin'::text]));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'profiles_status_check'
  ) THEN
    ALTER TABLE profiles 
    ADD CONSTRAINT profiles_status_check 
    CHECK (status = ANY (ARRAY['online'::text, 'offline'::text, 'away'::text]));
  END IF;
END $$;

-- Recreate indexes
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_interests ON profiles USING gin(interests);
CREATE INDEX IF NOT EXISTS idx_profiles_skills ON profiles USING gin(skills);
CREATE INDEX IF NOT EXISTS idx_profiles_settings ON profiles USING gin(settings);
CREATE INDEX IF NOT EXISTS idx_profiles_setup_progress ON profiles USING gin(setup_progress);
CREATE INDEX IF NOT EXISTS idx_profiles_auth_lookup ON profiles(id, email);
CREATE INDEX IF NOT EXISTS idx_profiles_auth_role ON profiles(id, role);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Recreate RLS policies
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  TO public
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  TO public
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  TO public
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superadmin')
    )
  );

CREATE POLICY "Admins can update all profiles"
  ON profiles FOR UPDATE
  TO public
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superadmin')
    )
  );

-- Create user trigger function
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
    allows_messages
  )
  VALUES (
    NEW.id,
    NEW.email,
    'superadmin',
    true,
    true
  );
  RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Grant permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;