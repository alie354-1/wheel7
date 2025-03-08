/*
  # App Settings Migration

  1. Purpose
    - Create app_settings table if not exists
    - Set up RLS policies
    - Insert default settings
    - Clean up old settings from profiles

  2. Changes
    - Create app_settings table with proper constraints
    - Enable RLS and create policies
    - Set up default configuration values
    - Update existing profile settings
*/

-- Create app_settings table if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'app_settings') THEN
    CREATE TABLE app_settings (
      id SERIAL PRIMARY KEY,
      key text UNIQUE NOT NULL,
      value jsonb DEFAULT '{}'::jsonb,
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now()
    );

    -- Enable RLS
    ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

    -- Create policies
    CREATE POLICY "Anyone can view app settings"
      ON app_settings
      FOR SELECT
      TO authenticated
      USING (true);

    CREATE POLICY "Admins can manage app settings"
      ON app_settings
      FOR ALL
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = auth.uid()
          AND role IN ('admin', 'superadmin')
        )
      );

    -- Insert default settings
    INSERT INTO app_settings (key, value) VALUES
      ('openai', jsonb_build_object(
        'api_key', '',
        'model', 'gpt-4'
      )),
      ('app_credentials', jsonb_build_object(
        'google', jsonb_build_object(
          'client_id', '',
          'client_secret', '',
          'redirect_uri', '',
          'project_id', '',
          'auth_uri', 'https://accounts.google.com/o/oauth2/auth',
          'token_uri', 'https://oauth2.googleapis.com/token',
          'auth_provider_x509_cert_url', 'https://www.googleapis.com/oauth2/v1/certs'
        )
      )),
      ('feature_flags', jsonb_build_object());
  END IF;
END $$;

-- Update profile settings safely
DO $$
BEGIN
  -- Only update profiles that have settings column
  UPDATE profiles
  SET settings = jsonb_build_object(
    'notifications', COALESCE(
      (settings->>'notifications')::jsonb,
      jsonb_build_object(
        'email', true,
        'push', true
      )
    ),
    'privacy', COALESCE(
      (settings->>'privacy')::jsonb,
      jsonb_build_object(
        'showProfile', true,
        'allowMessages', true
      )
    )
  )
  WHERE settings IS NOT NULL;
END $$;