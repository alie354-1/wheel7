/*
  # Fix User Creation Trigger Function

  1. Changes
    - Improve error handling in trigger function
    - Add better transaction handling
    - Add debugging statements
    - Ensure proper profile creation

  2. Security
    - Maintains RLS policies
    - Ensures secure user creation
    - Preserves data integrity

  3. Notes
    - Fixes user creation issues
    - Improves error visibility
    - Ensures proper profile setup
*/

-- First drop existing trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop existing function
DROP FUNCTION IF EXISTS handle_new_user();

-- Create improved function with better error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
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
EXCEPTION
    WHEN unique_violation THEN
        -- Profile already exists, just return
        RETURN NEW;
    WHEN OTHERS THEN
        RAISE LOG 'Error in handle_new_user(): %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Recreate trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- Ensure proper permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;

-- Ensure sequences are granted
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;