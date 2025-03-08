/*
  # Fix standup tasks RLS policies

  1. Security Changes
    - Enable RLS on standup_tasks table
    - Add policy for task owners to manage their tasks
    - Add policy for assigned users to view their tasks

  2. Changes
    - Drop any existing policies to avoid conflicts
    - Create new policies with proper conditions
    - Ensure both task creators and assignees have appropriate access
*/

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can manage their own tasks" ON standup_tasks;
DROP POLICY IF EXISTS "Users can view tasks assigned to them" ON standup_tasks;
DROP POLICY IF EXISTS "standup_tasks_owner_policy" ON standup_tasks;
DROP POLICY IF EXISTS "standup_tasks_assignee_policy" ON standup_tasks;

-- Enable RLS
ALTER TABLE standup_tasks ENABLE ROW LEVEL SECURITY;

-- Policy for task owners (users who created the standup entry)
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

-- Policy for assigned users to view their tasks
CREATE POLICY "standup_tasks_assignee_policy"
ON standup_tasks
FOR SELECT
TO authenticated
USING (assigned_to = auth.uid());