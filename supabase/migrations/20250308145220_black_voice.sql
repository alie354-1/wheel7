/*
  # Create Super Admin Profile

  1. Changes
    - Creates a super admin profile if the user exists
    - Adds appropriate error handling
    - Includes safety checks

  2. Security
    - Only creates profile if user exists
    - Maintains data integrity
    - Preserves existing profile data
*/

-- Create enum type if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('user', 'admin', 'superadmin');
  END IF;
END $$;

-- Function to safely create or update super admin profile
CREATE OR REPLACE FUNCTION create_super_admin_profile(admin_email text)
RETURNS void AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Get the user ID from auth.users
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = admin_email
  LIMIT 1;

  -- Only proceed if we found the user
  IF v_user_id IS NOT NULL THEN
    -- Create or update profile
    INSERT INTO profiles (
      id,
      email,
      full_name,
      role,
      is_public,
      allows_messages,
      created_at,
      updated_at
    ) VALUES (
      v_user_id,
      admin_email,
      'Alie Cohen',
      'superadmin',
      true,
      true,
      now(),
      now()
    )
    ON CONFLICT (id) DO UPDATE
    SET
      role = 'superadmin',
      updated_at = now();
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Execute the function
SELECT create_super_admin_profile('aliecohen@gmail.com');

-- Clean up by dropping the function
DROP FUNCTION create_super_admin_profile(text);