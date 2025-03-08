/*
  # Fix User Creation and Permissions

  1. Changes
    - Drop and recreate trigger function for new user handling
    - Set default role to superadmin
    - Update permissions and grants
    - Skip existing policy creation

  2. Security
    - Maintains proper security context
    - Preserves existing RLS policies
    - Updates necessary permissions

  3. Notes
    - Fixes user creation process
    - Avoids duplicate policy creation
    - Maintains data integrity
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop existing function
DROP FUNCTION IF EXISTS handle_new_user();

-- Create improved function with proper permissions
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Create profile entry
    INSERT INTO public.profiles (
        id,
        email,
        role,
        is_public,
        allows_messages,
        settings,
        setup_progress
    )
    VALUES (
        NEW.id,
        NEW.email,
        'superadmin',
        true,
        true,
        jsonb_build_object(
            'notifications', jsonb_build_object('email', true, 'push', true),
            'privacy', jsonb_build_object('showProfile', true, 'allowMessages', true),
            'app_credentials', jsonb_build_object(),
            'feature_flags', jsonb_build_object(),
            'openai', jsonb_build_object(),
            'cloud_storage', jsonb_build_object()
        ),
        jsonb_build_object(
            'current_step', 'basic',
            'completed_steps', ARRAY[]::text[],
            'form_data', '{}'::jsonb
        )
    );

    RETURN NEW;
END;
$$;

-- Recreate trigger with proper permissions
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT USAGE ON SCHEMA auth TO postgres, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;

-- Grant specific permissions for auth schema
GRANT SELECT ON auth.users TO service_role;
GRANT SELECT ON auth.users TO postgres;

-- Ensure sequences are granted
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;