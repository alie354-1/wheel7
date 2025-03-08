/*
  # Add Profile Fields Migration

  1. New Columns
    - Professional background
    - Skills and expertise
    - Education and experience
    - Preferences and interests
    - Availability and status
    - Languages and timezone
    - Achievements and goals

  2. Data Types
    - Arrays for skills, languages, etc.
    - JSONB for structured data
    - Text for descriptions
    - Enums for statuses

  3. Constraints
    - Default values
    - Valid status values
    - Array defaults
*/

-- Add new columns to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS professional_background text,
ADD COLUMN IF NOT EXISTS skills text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS industry_experience text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS previous_startups jsonb DEFAULT '[]',
ADD COLUMN IF NOT EXISTS education jsonb DEFAULT '[]',
ADD COLUMN IF NOT EXISTS social_links jsonb DEFAULT '{}',
ADD COLUMN IF NOT EXISTS interests text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS goals text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS availability_status text DEFAULT 'part-time',
ADD COLUMN IF NOT EXISTS mentor_preferences jsonb DEFAULT '{}',
ADD COLUMN IF NOT EXISTS investment_interests jsonb DEFAULT '{}',
ADD COLUMN IF NOT EXISTS timezone text,
ADD COLUMN IF NOT EXISTS languages text[] DEFAULT ARRAY['English'],
ADD COLUMN IF NOT EXISTS achievements text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS looking_for text[] DEFAULT '{}';

-- Update any existing rows to have a valid status
UPDATE profiles 
SET availability_status = 'part-time' 
WHERE availability_status IS NULL 
   OR availability_status NOT IN ('full-time', 'part-time', 'weekends', 'evenings', 'not-available');

-- Add constraint for availability_status
DO $$ 
BEGIN
  ALTER TABLE profiles
  ADD CONSTRAINT valid_availability_status 
  CHECK (availability_status IN ('full-time', 'part-time', 'weekends', 'evenings', 'not-available'));
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;