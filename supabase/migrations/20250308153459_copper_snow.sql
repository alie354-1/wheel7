/*
  # Add Missing Profile Columns

  1. Changes
    - Add missing columns to profiles table
    - Set appropriate defaults and constraints
    - Add missing columns referenced in the application

  2. Schema Updates
    - Add bio column
    - Add company column
    - Add headline column
    - Add timezone column
    - Add languages column
    - Add achievements column
    - Add looking_for column
    - Add cloud_storage column
*/

-- Add missing columns if they don't exist
DO $$ BEGIN
  -- Bio column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'bio') THEN
    ALTER TABLE profiles ADD COLUMN bio text;
  END IF;

  -- Company column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'company') THEN
    ALTER TABLE profiles ADD COLUMN company text;
  END IF;

  -- Headline column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'headline') THEN
    ALTER TABLE profiles ADD COLUMN headline text;
  END IF;

  -- Timezone column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'timezone') THEN
    ALTER TABLE profiles ADD COLUMN timezone text;
  END IF;

  -- Languages column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'languages') THEN
    ALTER TABLE profiles ADD COLUMN languages text[] DEFAULT ARRAY['English'::text];
  END IF;

  -- Achievements column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'achievements') THEN
    ALTER TABLE profiles ADD COLUMN achievements text[] DEFAULT '{}'::text[];
  END IF;

  -- Looking for column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'looking_for') THEN
    ALTER TABLE profiles ADD COLUMN looking_for text[] DEFAULT '{}'::text[];
  END IF;

  -- Cloud storage column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'cloud_storage') THEN
    ALTER TABLE profiles ADD COLUMN cloud_storage jsonb DEFAULT '{}'::jsonb;
  END IF;
END $$;

-- Update existing profiles with default values for languages
UPDATE profiles 
SET languages = ARRAY['English'::text] 
WHERE languages IS NULL;

-- Update existing profiles with default values for achievements
UPDATE profiles 
SET achievements = '{}'::text[] 
WHERE achievements IS NULL;

-- Update existing profiles with default values for looking_for
UPDATE profiles 
SET looking_for = '{}'::text[] 
WHERE looking_for IS NULL;

-- Update existing profiles with default values for cloud_storage
UPDATE profiles 
SET cloud_storage = '{}'::jsonb 
WHERE cloud_storage IS NULL;

-- Add comment explaining the columns
COMMENT ON TABLE profiles IS 'User profile information including personal details, preferences, and integrations';