/*
  # Fix RLS policies for standup tasks

  1. Security Changes
    - Drop existing policies
    - Enable RLS
    - Add policy for users to manage their own tasks
    - Add policy for users to view assigned tasks

  2. Changes
    - Drop existing policies to avoid conflicts
    - Re-enable RLS
    - Create new policies with fixed names
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can manage their own tasks" ON standup_tasks;
DROP POLICY IF EXISTS "Users can view tasks assigned to them" ON standup_tasks;

-- Enable RLS
ALTER TABLE standup_tasks ENABLE ROW LEVEL SECURITY;

-- Policy for users to manage their own tasks
CREATE POLICY "standup_tasks_owner_policy"
  ON standup_tasks
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM standup_entries
      WHERE standup_entries.id = standup_tasks.standup_entry_id
      AND standup_entries.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM standup_entries
      WHERE standup_entries.id = standup_tasks.standup_entry_id
      AND standup_entries.user_id = auth.uid()
    )
  );

-- Policy for users to view tasks assigned to them
CREATE POLICY "standup_tasks_assignee_policy"
  ON standup_tasks
  FOR SELECT
  TO authenticated
  USING (assigned_to = auth.uid());