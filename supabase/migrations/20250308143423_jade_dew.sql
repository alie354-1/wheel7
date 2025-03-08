/*
  # Categories Table Setup

  1. New Tables
    - categories: Content organization categories
      - id: Primary key (uuid)
      - name: Category name (text)
      - description: Category description (text)
      - slug: URL-friendly identifier (text)
      - color: Category color code (text) 
      - icon: Category icon name (text)
      - created_at: Creation timestamp
      - updated_at: Last update timestamp

  2. Security
    - RLS enabled
    - Public viewing policy
    - Admin management policy

  3. Data
    - Default categories inserted
*/

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  slug text NOT NULL UNIQUE,
  color text,
  icon text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create index on categories
CREATE INDEX IF NOT EXISTS categories_slug_idx ON categories(slug);

-- Enable RLS on categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Categories policies
CREATE POLICY "Anyone can view categories"
  ON categories FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Admins can manage categories"
  ON categories FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superadmin')
    )
  );

-- Insert default categories
INSERT INTO categories (name, description, slug, color, icon)
VALUES
  ('General Discussion', 'General startup and entrepreneurship discussions', 'general', '#6366F1', 'MessageSquare'),
  ('Technical', 'Technical discussions and questions', 'technical', '#EC4899', 'Code'),
  ('Marketing', 'Marketing strategies and tips', 'marketing', '#10B981', 'TrendingUp'),
  ('Funding', 'Fundraising and investment discussions', 'funding', '#F59E0B', 'DollarSign'),
  ('Product', 'Product development and management', 'product', '#3B82F6', 'Box'),
  ('Design', 'Design and UX discussions', 'design', '#8B5CF6', 'Palette'),
  ('Legal', 'Legal advice and discussions', 'legal', '#EF4444', 'Scale'),
  ('Hiring', 'Hiring and team building', 'hiring', '#14B8A6', 'Users')
ON CONFLICT (slug) DO NOTHING;