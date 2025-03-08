/*
  # Messaging System Setup

  1. Profile Updates
    - Add messaging-related columns to profiles table
    - Add online status tracking

  2. New Tables
    - `conversations` for managing chat threads between users
    - `messages` for storing individual messages

  3. Security
    - Enable RLS on all new tables
    - Set up policies for conversations and messages
    - Ensure proper access control

  4. Performance
    - Add indexes for common queries
    - Optimize conversation lookups
*/

-- Add new columns to profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS allows_messages boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS status text CHECK (status IN ('online', 'offline', 'away')),
ADD COLUMN IF NOT EXISTS last_seen timestamptz;

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL,
  sender_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipient_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content text NOT NULL,
  read_at timestamptz,
  deleted_by_sender boolean DEFAULT false,
  deleted_by_recipient boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  participant1_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  participant2_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_message_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT participants_different CHECK (participant1_id != participant2_id),
  UNIQUE(participant1_id, participant2_id)
);

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view their conversations" ON conversations;
  DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
  DROP POLICY IF EXISTS "Users can update their conversations" ON conversations;
  DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
  DROP POLICY IF EXISTS "Users can send messages" ON messages;
  DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
EXCEPTION
  WHEN undefined_object THEN null;
END $$;

-- Conversation policies
CREATE POLICY "Users can view their conversations"
  ON conversations
  FOR SELECT
  USING (
    auth.uid() IN (participant1_id, participant2_id)
  );

CREATE POLICY "Users can create conversations"
  ON conversations
  FOR INSERT
  WITH CHECK (
    auth.uid() IN (participant1_id, participant2_id)
  );

CREATE POLICY "Users can update their conversations"
  ON conversations
  FOR UPDATE
  USING (
    auth.uid() IN (participant1_id, participant2_id)
  );

-- Message policies
CREATE POLICY "Users can view messages in their conversations"
  ON messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = conversation_id
      AND auth.uid() IN (c.participant1_id, c.participant2_id)
    )
  );

CREATE POLICY "Users can send messages"
  ON messages
  FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = conversation_id
      AND auth.uid() IN (c.participant1_id, c.participant2_id)
    )
  );

CREATE POLICY "Users can update their own messages"
  ON messages
  FOR UPDATE
  USING (
    auth.uid() IN (sender_id, recipient_id)
  );

-- Drop existing indexes if they exist
DROP INDEX IF EXISTS messages_conversation_id_idx;
DROP INDEX IF EXISTS messages_sender_id_idx;
DROP INDEX IF EXISTS messages_recipient_id_idx;
DROP INDEX IF EXISTS messages_created_at_idx;
DROP INDEX IF EXISTS conversations_participant1_id_idx;
DROP INDEX IF EXISTS conversations_participant2_id_idx;
DROP INDEX IF EXISTS conversations_last_message_at_idx;

-- Create indexes for better performance
CREATE INDEX messages_conversation_id_idx ON messages(conversation_id);
CREATE INDEX messages_sender_id_idx ON messages(sender_id);
CREATE INDEX messages_recipient_id_idx ON messages(recipient_id);
CREATE INDEX messages_created_at_idx ON messages(created_at);
CREATE INDEX conversations_participant1_id_idx ON conversations(participant1_id);
CREATE INDEX conversations_participant2_id_idx ON conversations(participant2_id);
CREATE INDEX conversations_last_message_at_idx ON conversations(last_message_at);

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_or_create_conversation(uuid, uuid);

-- Helper function to get or create a conversation
CREATE OR REPLACE FUNCTION get_or_create_conversation(user1_id uuid, user2_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  conv_id uuid;
BEGIN
  -- Try to find existing conversation
  SELECT id INTO conv_id
  FROM conversations
  WHERE (participant1_id = user1_id AND participant2_id = user2_id)
     OR (participant1_id = user2_id AND participant2_id = user1_id)
  LIMIT 1;

  -- Create new conversation if none exists
  IF conv_id IS NULL THEN
    INSERT INTO conversations (participant1_id, participant2_id)
    VALUES (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id))
    RETURNING id INTO conv_id;
  END IF;

  RETURN conv_id;
END;
$$;