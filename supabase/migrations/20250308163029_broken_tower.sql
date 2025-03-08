/*
  # Task Management Policies

  1. Security
    - Enable RLS on standup_tasks table
    - Add policies for task management
    - Add policies for task viewing

  2. Policies
    - Users can manage tasks they created
    - Users can manage tasks from their standups
    - Users can view tasks assigned to them
*/

-- Enable RLS
ALTER TABLE standup_tasks ENABLE ROW LEVEL SECURITY;

-- Policy for users to manage tasks they created or are assigned to
CREATE POLICY "Users can manage their tasks"
  ON standup_tasks
  FOR ALL
  TO authenticated
  USING (
    assigned_to = auth.uid() OR
    EXISTS (
      SELECT 1 FROM standup_entries
      WHERE standup_entries.id = standup_tasks.standup_entry_id
      AND standup_entries.user_id = auth.uid()
    )
  )
  WITH CHECK (
    assigned_to = auth.uid() OR
    EXISTS (
      SELECT 1 FROM standup_entries
      WHERE standup_entries.id = standup_tasks.standup_entry_id
      AND standup_entries.user_id = auth.uid()
    )
  );