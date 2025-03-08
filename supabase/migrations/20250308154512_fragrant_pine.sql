/*
  # Add location column to profiles table

  1. Changes
    - Add location column to profiles table
    - Add comment explaining the column purpose

  2. Details
    - Column: location (text, nullable)
    - Comment: User's physical location (city, country)
*/

-- Add location column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' 
    AND column_name = 'location'
  ) THEN
    ALTER TABLE profiles ADD COLUMN location text;
    COMMENT ON COLUMN profiles.location IS 'User''s physical location (city, country)';
  END IF;
END $$;