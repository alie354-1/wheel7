/*
  # AI Discussions and Standups Schema

  1. New Tables
    - ai_discussions: Stores AI chat conversations
    - standup_entries: Daily standup records
    - standup_tasks: Task management system

  2. Security
    - RLS enabled on all tables
    - User-specific access controls
    - Public/private visibility options

  3. Features
    - AI chat history
    - Daily standups
    - Task tracking
    - AI insights
*/

-- Create ai_discussions table
CREATE TABLE IF NOT EXISTS ai_discussions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  messages jsonb NOT NULL,
  context jsonb,
  is_public boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create standup_entries table
CREATE TABLE IF NOT EXISTS standup_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  date date NOT NULL,
  accomplished text NOT NULL,
  working_on text NOT NULL,
  blockers text,
  goals text NOT NULL,
  feedback text,
  follow_up_questions jsonb,
  ai_insights jsonb DEFAULT jsonb_build_object(
    'risks', ARRAY[]::text[],
    'strengths', ARRAY[]::text[],
    'opportunities', ARRAY[]::text[],
    'recommendations', ARRAY[]::text[],
    'areas_for_improvement', ARRAY[]::text[]
  ),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create standup_tasks table
CREATE TABLE IF NOT EXISTS standup_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  standup_entry_id uuid REFERENCES standup_entries(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  priority text NOT NULL CHECK (priority IN ('low', 'medium', 'high')),
  status text DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'in_progress', 'completed')),
  category text DEFAULT 'personal' NOT NULL,
  task_type text DEFAULT 'Other' NOT NULL,
  estimated_hours numeric DEFAULT 1,
  due_date date NOT NULL,
  assigned_to uuid REFERENCES auth.users(id),
  completed_at timestamptz,
  implementation_tips text[] DEFAULT '{}'::text[],
  potential_challenges text[] DEFAULT '{}'::text[],
  success_metrics text[] DEFAULT '{}'::text[],
  resources jsonb DEFAULT '[]'::jsonb,
  learning_resources jsonb DEFAULT '[]'::jsonb,
  tools jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_ai_discussions_user ON ai_discussions(user_id);
CREATE INDEX IF NOT EXISTS idx_standup_entries_user ON standup_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_standup_tasks_entry ON standup_tasks(standup_entry_id);

-- Enable RLS
ALTER TABLE ai_discussions ENABLE ROW LEVEL SECURITY;
ALTER TABLE standup_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE standup_tasks ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Drop AI discussions policies
  DROP POLICY IF EXISTS "Users can manage their own discussions" ON ai_discussions;
  DROP POLICY IF EXISTS "Public discussions are viewable by everyone" ON ai_discussions;
  
  -- Drop standup entries policies
  DROP POLICY IF EXISTS "Users can manage their own standup entries" ON standup_entries;
  
  -- Drop standup tasks policies
  DROP POLICY IF EXISTS "Users can manage their own tasks" ON standup_tasks;
EXCEPTION
  WHEN undefined_object THEN
    NULL;
END $$;

-- Create policies
-- AI Discussions
CREATE POLICY "Users can manage their own discussions"
  ON ai_discussions FOR ALL
  TO public
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Public discussions are viewable by everyone"
  ON ai_discussions FOR SELECT
  TO public
  USING (is_public = true);

-- Standup Entries
CREATE POLICY "Users can manage their own standup entries"
  ON standup_entries FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Standup Tasks
CREATE POLICY "Users can manage their own tasks"
  ON standup_tasks FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM standup_entries
      WHERE id = standup_entry_id
      AND user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM standup_entries
      WHERE id = standup_entry_id
      AND user_id = auth.uid()
    )
  );