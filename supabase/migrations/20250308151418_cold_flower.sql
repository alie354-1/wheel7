/*
  # Set Superadmin as Default Role

  1. Changes
    - Update handle_new_user function to set role as 'superadmin' by default
    - Ensure existing users are updated to superadmin role

  2. Security
    - Maintains existing RLS policies
    - Updates user roles safely

  3. Notes
    - All new users will be created as superadmins
    - Existing users will be updated to superadmin role
*/

-- Update the handle_new_user function to set superadmin as default role
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, email, role)
    VALUES (new.id, new.email, 'superadmin');
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update existing users to superadmin role
UPDATE profiles 
SET role = 'superadmin'::user_role 
WHERE role != 'superadmin';