/*
  # Slack Settings Table

  1. Tables
    - slack_settings: Slack integration settings

  2. Features
    - Slack workspace configuration
    - Bot token storage
    - Integration management

  Note: Policies are already created in a previous migration
*/

-- Create slack_settings table if it doesn't exist
DO $$ BEGIN
  CREATE TABLE IF NOT EXISTS slack_settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id text NOT NULL,
    bot_token text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
  );
EXCEPTION
  WHEN duplicate_table THEN
    NULL;
END $$;

-- Enable RLS if not already enabled
DO $$ BEGIN
  ALTER TABLE slack_settings ENABLE ROW LEVEL SECURITY;
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
END $$;