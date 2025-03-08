/*
  # Authentication Schema Setup

  1. Tables
    - profiles: User profiles with role-based access
    - app_settings: Application configuration
    - slack_settings: Slack integration settings

  2. Security
    - Row Level Security (RLS) policies
    - Role-based access control
    - Secure defaults

  3. Features
    - User profile management
    - Role management
    - Application settings
    - Slack integration
*/

-- Check if user_role type exists and create if not
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('user', 'admin', 'superadmin');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Create profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  role user_role DEFAULT 'user',
  is_public boolean DEFAULT false,
  allows_messages boolean DEFAULT true,
  avatar_url text,
  professional_background text,
  skills text[],
  interests text[] DEFAULT '{}'::text[],
  status text CHECK (status IN ('online', 'offline', 'away')),
  last_seen timestamptz,
  industry_experience text[] DEFAULT '{}'::text[],
  previous_startups jsonb DEFAULT '[]'::jsonb,
  education jsonb DEFAULT '[]'::jsonb,
  goals text[] DEFAULT '{}'::text[],
  availability_status text DEFAULT 'part-time' CHECK (availability_status IN ('full-time', 'part-time', 'weekends', 'evenings', 'not-available')),
  mentor_preferences jsonb DEFAULT '{}'::jsonb,
  investment_interests jsonb DEFAULT '{}'::jsonb,
  timezone text,
  languages text[] DEFAULT ARRAY['English'::text],
  achievements text[] DEFAULT '{}'::text[],
  looking_for text[] DEFAULT '{}'::text[],
  social_links jsonb DEFAULT '{}'::jsonb,
  settings jsonb DEFAULT jsonb_build_object(
    'notifications', jsonb_build_object('email', true, 'push', true),
    'privacy', jsonb_build_object('showProfile', true, 'allowMessages', true),
    'app_credentials', jsonb_build_object(),
    'feature_flags', jsonb_build_object(),
    'openai', jsonb_build_object(),
    'cloud_storage', jsonb_build_object()
  ),
  setup_progress jsonb DEFAULT jsonb_build_object(
    'current_step', 'basic',
    'completed_steps', ARRAY[]::text[],
    'form_data', '{}'::jsonb
  ),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create app_settings table if it doesn't exist
CREATE TABLE IF NOT EXISTS app_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE CHECK (key IN ('openai', 'app_credentials', 'feature_flags')),
  value jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create slack_settings table if it doesn't exist
CREATE TABLE IF NOT EXISTS slack_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id text NOT NULL,
  bot_token text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_skills ON profiles USING gin(skills);
CREATE INDEX IF NOT EXISTS idx_profiles_interests ON profiles USING gin(interests);
CREATE INDEX IF NOT EXISTS idx_profiles_settings ON profiles USING gin(settings);
CREATE INDEX IF NOT EXISTS idx_profiles_setup_progress ON profiles USING gin(setup_progress);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE slack_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Profiles policies
  DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
  DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
  DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
  DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
  DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
  DROP POLICY IF EXISTS "Users can view their own settings" ON profiles;
  DROP POLICY IF EXISTS "Users can update their own settings" ON profiles;
  DROP POLICY IF EXISTS "Users can view all settings" ON profiles;
  
  -- App settings policies
  DROP POLICY IF EXISTS "Admins can manage app settings" ON app_settings;
  DROP POLICY IF EXISTS "Anyone can view app settings" ON app_settings;
  
  -- Slack settings policies
  DROP POLICY IF EXISTS "Admins can manage slack settings" ON slack_settings;
EXCEPTION
  WHEN undefined_object THEN NULL;
END $$;

-- Create policies for profiles
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  TO public
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  TO public
  USING (auth.uid() = id);

CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT
  TO public
  USING (is_public = true);

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

-- Create policies for app_settings
CREATE POLICY "Admins can manage app settings"
  ON app_settings FOR ALL
  TO public
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superadmin')
    )
  );

CREATE POLICY "Anyone can view app settings"
  ON app_settings FOR SELECT
  TO public
  USING (true);

-- Create policies for slack_settings
CREATE POLICY "Admins can manage slack settings"
  ON slack_settings FOR ALL
  TO public
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superadmin')
    )
  );

-- Create or replace trigger function for new user profile creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'user');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate trigger for new user profile creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();