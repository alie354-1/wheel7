/*
  # Categories Table Updates

  1. Changes
    - Add unique constraint on slug if not exists
    - Create index on slug if not exists
    - Enable RLS if not already enabled
    - Add policies if not exists
    - Insert default categories

  2. Security
    - Enable RLS
    - Add view and manage policies
*/

-- Add unique constraint if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'categories_slug_key'
  ) THEN
    ALTER TABLE categories ADD CONSTRAINT categories_slug_key UNIQUE (slug);
  END IF;
END $$;

-- Create index if not exists
CREATE INDEX IF NOT EXISTS categories_slug_idx ON categories(slug);

-- Enable RLS if not already enabled
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Create policies (will be skipped if they already exist)
DO $$ 
BEGIN
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
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

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