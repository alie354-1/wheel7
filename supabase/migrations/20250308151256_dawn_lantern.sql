/*
  # Fix Database Schema Setup

  1. Changes
    - Create base tables with proper constraints
    - Set up RLS policies
    - Create necessary indexes
    - Add trigger for new user creation

  2. Security
    - Enable RLS on all tables
    - Set up proper policies
    - Add proper constraints

  3. Notes
    - Safe creation of objects
    - Handles existing tables
    - Proper error handling
*/

-- Create user_role type if it doesn't exist
DO $$ 
BEGIN
    CREATE TYPE user_role AS ENUM ('user', 'admin', 'superadmin');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Create profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email text NOT NULL,
    full_name text,
    role user_role NOT NULL DEFAULT 'user',
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

-- Create or replace function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, email, role)
    VALUES (new.id, new.email, 'user');
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- Drop existing policies
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Enable read access for own profile" ON profiles;
    DROP POLICY IF EXISTS "Enable update access for own profile" ON profiles;
    DROP POLICY IF EXISTS "Enable read access for public profiles" ON profiles;
    DROP POLICY IF EXISTS "Enable admin access to all profiles" ON profiles;
    DROP POLICY IF EXISTS "Enable admin access to app settings" ON app_settings;
    DROP POLICY IF EXISTS "Enable read access to app settings" ON app_settings;
    DROP POLICY IF EXISTS "Enable admin access to slack settings" ON slack_settings;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Create RLS policies
CREATE POLICY "Enable read access for own profile"
    ON profiles FOR SELECT
    TO public
    USING (auth.uid() = id);

CREATE POLICY "Enable update access for own profile"
    ON profiles FOR UPDATE
    TO public
    USING (auth.uid() = id);

CREATE POLICY "Enable read access for public profiles"
    ON profiles FOR SELECT
    TO public
    USING (is_public = true);

CREATE POLICY "Enable admin access to all profiles"
    ON profiles FOR ALL
    TO public
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('admin', 'superadmin')
        )
    );

CREATE POLICY "Enable admin access to app settings"
    ON app_settings FOR ALL
    TO public
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('admin', 'superadmin')
        )
    );

CREATE POLICY "Enable read access to app settings"
    ON app_settings FOR SELECT
    TO public
    USING (true);

CREATE POLICY "Enable admin access to slack settings"
    ON slack_settings FOR ALL
    TO public
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('admin', 'superadmin')
        )
    );