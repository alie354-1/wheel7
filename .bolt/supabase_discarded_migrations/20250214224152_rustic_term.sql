-- Drop existing tables if they exist
DROP TABLE IF EXISTS standup_tasks;
DROP TABLE IF EXISTS standup_entries;

-- Create standup_entries table
CREATE TABLE standup_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  date date NOT NULL,
  accomplished text NOT NULL,
  working_on text NOT NULL,
  blockers text,
  goals text NOT NULL,
  feedback text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create standup tasks table
CREATE TABLE standup_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  standup_entry_id uuid REFERENCES standup_entries(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  priority text NOT NULL CHECK (priority IN ('low', 'medium', 'high')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
  due_date date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE standup_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE standup_tasks ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own standup entries"
  ON standup_entries
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own standup entries"
  ON standup_entries
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own standup entries"
  ON standup_entries
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own standup tasks"
  ON standup_tasks
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM standup_entries
      WHERE id = standup_tasks.standup_entry_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create their own standup tasks"
  ON standup_tasks
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM standup_entries
      WHERE id = standup_tasks.standup_entry_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own standup tasks"
  ON standup_tasks
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM standup_entries
      WHERE id = standup_tasks.standup_entry_id
      AND user_id = auth.uid()
    )
  );

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_standup_entries_user_id ON standup_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_standup_entries_date ON standup_entries(date);
CREATE INDEX IF NOT EXISTS idx_standup_tasks_entry_id ON standup_tasks(standup_entry_id);