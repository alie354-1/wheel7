/*
  # Add Location Column to Profiles

  1. New Columns
    - location (text): User's physical location

  2. Changes
    - Add location column if it doesn't exist
*/

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'location') THEN
    ALTER TABLE profiles ADD COLUMN "location" text;
  END IF;
END $$;

-- Add comment explaining the column
COMMENT ON COLUMN profiles.location IS 'User''s physical location (city, country)';