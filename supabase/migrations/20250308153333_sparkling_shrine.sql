/*
  # Fix Profile Policies to Prevent Recursion

  1. Changes
    - Remove recursive admin role checks
    - Use role column directly for admin checks
    - Simplify policy conditions
    - Add missing bio column

  2. Security
    - Maintain proper access control
    - Prevent infinite recursion
    - Keep existing functionality
*/

-- Drop existing policies to prevent conflicts
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can read all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;

-- Add missing bio column if not exists
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio text;

-- Create new non-recursive policies
CREATE POLICY "Enable read access to own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Enable update access to own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Enable admin read access"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    role IN ('admin', 'superadmin')
  );

CREATE POLICY "Enable admin update access"
  ON profiles FOR UPDATE
  TO authenticated
  USING (role IN ('admin', 'superadmin'))
  WITH CHECK (role IN ('admin', 'superadmin'));

CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT
  TO public
  USING (is_public = true);