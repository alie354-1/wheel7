/*
  # App Settings Migration

  1. Changes
    - Drop and recreate app_settings table
    - Add RLS policies for access control
    - Insert default settings for OpenAI, Google credentials, and feature flags
  
  2. Security
    - Enable RLS
    - Add policies for public viewing and admin management
  
  3. Default Data
    - OpenAI configuration
    - Google OAuth credentials
    - Feature flags
*/

-- Drop and recreate app_settings table
DROP TABLE IF EXISTS app_settings;

CREATE TABLE app_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text UNIQUE NOT NULL CHECK (key = ANY (ARRAY['openai', 'app_credentials', 'feature_flags'])),
  value jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view app settings" ON app_settings;
DROP POLICY IF EXISTS "Admins can manage app settings" ON app_settings;

-- Create policies
CREATE POLICY "Anyone can view app settings"
  ON app_settings
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Admins can manage app settings"
  ON app_settings
  FOR ALL
  TO public
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superadmin')
    )
  );

-- Insert default settings
INSERT INTO app_settings (key, value)
VALUES 
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
  ('feature_flags', jsonb_build_object())
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value,
    updated_at = now();