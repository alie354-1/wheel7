/*
  # Create Superadmin User Migration

  1. Purpose
    - Create initial superadmin user if not exists
    - Set up required profile and permissions
    - Handle existing user gracefully

  2. Changes
    - Check for existing user
    - Create auth.users entry if needed
    - Create profiles entry if needed
    - Set superadmin role and permissions
*/

DO $$ 
DECLARE
  user_id uuid;
  admin_email text := 'alie@jointhewheel.com';
BEGIN
  -- Check if user already exists in auth.users
  SELECT id INTO user_id
  FROM auth.users
  WHERE email = admin_email;

  -- Create user if doesn't exist
  IF user_id IS NULL THEN
    user_id := gen_random_uuid();
    
    INSERT INTO auth.users (
      id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_user_meta_data,
      created_at,
      updated_at,
      last_sign_in_at,
      confirmation_sent_at,
      is_super_admin
    ) VALUES (
      user_id,
      admin_email,
      crypt('test123', gen_salt('bf')),
      now(),
      '{"full_name": "Alie"}',
      now(),
      now(),
      now(),
      now(),
      true
    );
  END IF;

  -- Check if profile exists
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = user_id) THEN
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
      user_id,
      admin_email,
      'Alie',
      'superadmin',
      true,
      true,
      now(),
      now()
    );
  END IF;

END $$;