/*
  # Messaging System Schema

  1. New Tables
    - conversations: Tracks conversations between users
    - messages: Stores individual messages

  2. Security
    - RLS enabled on all tables
    - Granular access policies for participants
    - Message privacy controls

  3. Features
    - Direct messaging
    - Read receipts
    - Message history
*/

-- Create conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  participant1_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  participant2_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  last_message_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(participant1_id, participant2_id),
  CHECK (participant1_id <> participant2_id)
);

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  recipient_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  content text NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_conversations_participants ON conversations(participant1_id, participant2_id);
CREATE INDEX IF NOT EXISTS conversations_participant1_id_idx ON conversations(participant1_id);
CREATE INDEX IF NOT EXISTS conversations_participant2_id_idx ON conversations(participant2_id);
CREATE INDEX IF NOT EXISTS conversations_last_message_at_idx ON conversations(last_message_at);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS messages_sender_id_idx ON messages(sender_id);
CREATE INDEX IF NOT EXISTS messages_recipient_id_idx ON messages(recipient_id);
CREATE INDEX IF NOT EXISTS messages_created_at_idx ON messages(created_at);
CREATE INDEX IF NOT EXISTS messages_conversation_id_idx ON messages(conversation_id);

-- Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Drop conversation policies
  DROP POLICY IF EXISTS "Users can view their conversations" ON conversations;
  DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
  DROP POLICY IF EXISTS "Users can update their conversations" ON conversations;
  
  -- Drop message policies
  DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
  DROP POLICY IF EXISTS "Users can send messages" ON messages;
  DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
EXCEPTION
  WHEN undefined_object THEN
    NULL;
END $$;

-- Create policies
-- Conversations
CREATE POLICY "Users can view their conversations"
  ON conversations FOR SELECT
  TO public
  USING (
    auth.uid() = participant1_id OR
    auth.uid() = participant2_id
  );

CREATE POLICY "Users can create conversations"
  ON conversations FOR INSERT
  TO public
  WITH CHECK (
    auth.uid() = participant1_id OR
    auth.uid() = participant2_id
  );

CREATE POLICY "Users can update their conversations"
  ON conversations FOR UPDATE
  TO public
  USING (
    auth.uid() = participant1_id OR
    auth.uid() = participant2_id
  );

-- Messages
CREATE POLICY "Users can view messages in their conversations"
  ON messages FOR SELECT
  TO public
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = messages.conversation_id
      AND (auth.uid() = c.participant1_id OR auth.uid() = c.participant2_id)
    )
  );

CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  TO public
  WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = messages.conversation_id
      AND (auth.uid() = c.participant1_id OR auth.uid() = c.participant2_id)
    )
  );

CREATE POLICY "Users can update their own messages"
  ON messages FOR UPDATE
  TO public
  USING (
    auth.uid() = sender_id OR
    auth.uid() = recipient_id
  );