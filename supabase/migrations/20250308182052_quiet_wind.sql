/*
  # Add Resources and Resource Linking Tables

  1. New Tables
    - `resources` - Stores reusable resources
      - `id` (uuid, primary key)
      - `title` (text)
      - `description` (text)
      - `url` (text)
      - `type` (text) - article, video, tool, etc.
      - `source` (text) - web, wheel, community
      - `author_id` (uuid) - For community resources
      - `is_public` (boolean)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `task_resources` - Links tasks to resources
      - `id` (uuid, primary key)
      - `task_id` (uuid)
      - `resource_id` (uuid)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on both tables
    - Add policies for resource access and creation
    - Add policies for task resource linking

  3. Changes
    - Update task tables to use resource linking
*/

-- Create resources table
CREATE TABLE IF NOT EXISTS resources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  url text NOT NULL,
  type text NOT NULL CHECK (type IN ('article', 'video', 'tool', 'template', 'guide')),
  source text NOT NULL CHECK (source IN ('web', 'wheel', 'community')),
  author_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  is_public boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create task_resources table
CREATE TABLE IF NOT EXISTS task_resources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid REFERENCES standup_tasks(id) ON DELETE CASCADE,
  resource_id uuid REFERENCES resources(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(task_id, resource_id)
);

-- Enable RLS
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_resources ENABLE ROW LEVEL SECURITY;

-- Resource policies
CREATE POLICY "Public resources are viewable by everyone" 
  ON resources FOR SELECT 
  USING (is_public = true);

CREATE POLICY "Users can view resources they authored" 
  ON resources FOR SELECT 
  USING (author_id = auth.uid());

CREATE POLICY "Users can manage their own resources" 
  ON resources FOR ALL 
  USING (author_id = auth.uid())
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "Admins can manage all resources" 
  ON resources FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'superadmin')
    )
  );

-- Task resource linking policies
CREATE POLICY "Users can view resources for their tasks" 
  ON task_resources FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM standup_tasks 
      WHERE id = task_id 
      AND assigned_to = auth.uid()
    )
  );

CREATE POLICY "Users can manage resources for their tasks" 
  ON task_resources FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM standup_tasks 
      WHERE id = task_id 
      AND assigned_to = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM standup_tasks 
      WHERE id = task_id 
      AND assigned_to = auth.uid()
    )
  );

-- Create indexes
CREATE INDEX IF NOT EXISTS resources_type_idx ON resources(type);
CREATE INDEX IF NOT EXISTS resources_source_idx ON resources(source);
CREATE INDEX IF NOT EXISTS resources_author_id_idx ON resources(author_id);
CREATE INDEX IF NOT EXISTS task_resources_task_id_idx ON task_resources(task_id);
CREATE INDEX IF NOT EXISTS task_resources_resource_id_idx ON task_resources(resource_id);