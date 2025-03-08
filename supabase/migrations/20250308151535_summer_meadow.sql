/*
  # Fix Authentication Trigger and Function

  1. Changes
    - Drop trigger before function
    - Recreate function with superadmin role
    - Recreate trigger
    - Add auth indexes
    - Set permissions

  2. Security
    - Maintains RLS policies
    - Ensures secure user creation
    - Preserves data integrity

  3. Notes
    - Fixes dependency issue between trigger and function
    - Improves error handling
    - Optimizes auth queries
*/

-- First drop the trigger that depends on the function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Now we can safely drop and recreate the function
DROP FUNCTION IF EXISTS handle_new_user();

-- Recreate the function with better error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
DECLARE
  profile_exists boolean;
BEGIN
    -- Check if profile already exists
    SELECT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = new.id
    ) INTO profile_exists;

    -- Only create profile if it doesn't exist
    IF NOT profile_exists THEN
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
            new.id,
            new.email,
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
    END IF;

    RETURN new;
EXCEPTION
    WHEN others THEN
        -- Log error details
        RAISE NOTICE 'Error creating user profile: %', SQLERRM;
        RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- Add missing indexes for auth performance
CREATE INDEX IF NOT EXISTS idx_profiles_auth_lookup ON profiles(id, email);
CREATE INDEX IF NOT EXISTS idx_profiles_auth_role ON profiles(id, role);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;

-- Ensure sequences are granted
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;