/*
  # Add answers column to standup_entries table

  1. Changes
    - Add `answers` JSONB column to `standup_entries` table with default empty object
    - Add index on `answers` column for better query performance
*/

-- Add answers column
ALTER TABLE standup_entries 
ADD COLUMN IF NOT EXISTS answers JSONB DEFAULT '{}'::jsonb;

-- Add index for better performance when querying answers
CREATE INDEX IF NOT EXISTS idx_standup_entries_answers 
ON standup_entries USING GIN (answers);