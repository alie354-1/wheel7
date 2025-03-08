/*
  # Add Missing Profile Columns

  1. New Columns
    - bio (text): User biography
    - company (text): Current company
    - headline (text): Professional headline
    - timezone (text): User's timezone
    - languages (text[]): Spoken languages
    - achievements (text[]): User achievements
    - looking_for (text[]): What user is looking for
    - cloud_storage (jsonb): Cloud storage settings
    - current_role (text): Current professional role

  2. Changes
    - Add all missing columns if they don't exist
    - Set default values for array and jsonb columns
    - Add table comment
*/

-- Add missing columns if they don't exist
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'bio') THEN
    ALTER TABLE profiles ADD COLUMN bio text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'company') THEN
    ALTER TABLE profiles ADD COLUMN company text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'headline') THEN
    ALTER TABLE profiles ADD COLUMN headline text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'timezone') THEN
    ALTER TABLE profiles ADD COLUMN timezone text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'languages') THEN
    ALTER TABLE profiles ADD COLUMN languages text[] DEFAULT ARRAY['English'::text];
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'achievements') THEN
    ALTER TABLE profiles ADD COLUMN achievements text[] DEFAULT '{}'::text[];
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'looking_for') THEN
    ALTER TABLE profiles ADD COLUMN looking_for text[] DEFAULT '{}'::text[];
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'cloud_storage') THEN
    ALTER TABLE profiles ADD COLUMN cloud_storage jsonb DEFAULT '{}'::jsonb;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'current_role') THEN
    ALTER TABLE profiles ADD COLUMN "current_role" text;
  END IF;
END $$;

-- Update existing profiles with default values
UPDATE profiles SET languages = ARRAY['English'::text] WHERE languages IS NULL;
UPDATE profiles SET achievements = '{}'::text[] WHERE achievements IS NULL;
UPDATE profiles SET looking_for = '{}'::text[] WHERE looking_for IS NULL;
UPDATE profiles SET cloud_storage = '{}'::jsonb WHERE cloud_storage IS NULL;

-- Add comment explaining the columns
COMMENT ON TABLE profiles IS 'User profile information including personal details, preferences, and integrations';