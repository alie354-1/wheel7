/*
  # Fix task creation and RLS policies

  1. Security Changes
    - Drop existing policies to avoid conflicts
    - Add policy for creating standalone tasks
    - Add policy for managing tasks linked to standups
    - Add policy for viewing assigned tasks

  2. Changes
    - Ensure users can create tasks without standup entries
    - Allow task management for task creators
    - Allow viewing for assigned users
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can manage their own tasks" ON standup_tasks;
DROP POLICY IF EXISTS "Users can view tasks assigned to them" ON standup_tasks;
DROP POLICY IF EXISTS "standup_tasks_owner_policy" ON standup_tasks;
DROP POLICY IF EXISTS "standup_tasks_assignee_policy" ON standup_tasks;

-- Enable RLS
ALTER TABLE standup_tasks ENABLE ROW LEVEL SECURITY;

-- Policy for creating and managing tasks
CREATE POLICY "task_creator_policy"
ON standup_tasks
FOR ALL
TO authenticated
USING (
  -- Allow access if user created the task through a standup
  (standup_entry_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM standup_entries
    WHERE standup_entries.id = standup_tasks.standup_entry_id
    AND standup_entries.user_id = auth.uid()
  ))
  OR
  -- Allow access if user created a standalone task
  (standup_entry_id IS NULL AND auth.uid() = assigned_to)
)
WITH CHECK (
  -- Allow creation if linked to user's standup
  (standup_entry_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM standup_entries
    WHERE standup_entries.id = standup_tasks.standup_entry_id
    AND standup_entries.user_id = auth.uid()
  ))
  OR
  -- Allow creation of standalone tasks
  (standup_entry_id IS NULL AND auth.uid() = assigned_to)
);

-- Policy for viewing assigned tasks
CREATE POLICY "task_assignee_policy"
ON standup_tasks
FOR SELECT
TO authenticated
USING (assigned_to = auth.uid());