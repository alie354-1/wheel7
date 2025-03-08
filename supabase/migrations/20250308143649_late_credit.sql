/*
  # Add category_id to community_posts table

  1. Changes
    - Adds category_id column to community_posts table
    - Creates index on category_id column
*/

-- Add category_id column to community_posts table
ALTER TABLE community_posts 
ADD COLUMN IF NOT EXISTS category_id uuid REFERENCES categories(id) ON DELETE SET NULL;

-- Create index on category_id
CREATE INDEX IF NOT EXISTS community_posts_category_id_idx ON community_posts(category_id);