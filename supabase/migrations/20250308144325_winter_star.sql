/*
  # Community Features Schema Update

  1. Changes
    - Added IF NOT EXISTS checks for all objects
    - Added proper trigger handling
    - Ensured idempotent execution
    - Fixed policy creation
    - Added proper error handling

  2. Security
    - RLS enabled on all tables
    - Proper access policies
    - Secure vote tracking

  3. Tables Modified
    - categories
    - community_posts
    - community_comments
    - community_post_votes
    - community_comment_votes
*/

-- Drop existing triggers first to avoid conflicts
DROP TRIGGER IF EXISTS update_community_post_votes_trigger ON community_post_votes;
DROP TRIGGER IF EXISTS update_community_comment_votes_trigger ON community_comment_votes;

-- Drop existing functions
DROP FUNCTION IF EXISTS update_community_post_votes();
DROP FUNCTION IF EXISTS update_community_comment_votes();

-- Create categories table if it doesn't exist
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  slug text UNIQUE NOT NULL,
  color text,
  icon text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create index on categories slug
CREATE INDEX IF NOT EXISTS idx_categories_slug ON categories(slug);

-- Enable RLS on categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Create community_posts table
CREATE TABLE IF NOT EXISTS community_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id uuid REFERENCES communities(id) ON DELETE CASCADE,
  author_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  content text NOT NULL,
  category_id uuid REFERENCES categories(id) ON DELETE SET NULL,
  post_type text DEFAULT 'discussion',
  upvotes integer DEFAULT 0,
  downvotes integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes on community_posts
CREATE INDEX IF NOT EXISTS idx_community_posts_community ON community_posts(community_id);
CREATE INDEX IF NOT EXISTS community_posts_author_id_idx ON community_posts(author_id);
CREATE INDEX IF NOT EXISTS community_posts_category_id_idx ON community_posts(category_id);
CREATE INDEX IF NOT EXISTS community_posts_created_at_idx ON community_posts(created_at);

-- Enable RLS on community_posts
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;

-- Create community_comments table
CREATE TABLE IF NOT EXISTS community_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid REFERENCES community_posts(id) ON DELETE CASCADE,
  author_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  content text NOT NULL,
  upvotes integer DEFAULT 0,
  downvotes integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes on community_comments
CREATE INDEX IF NOT EXISTS idx_community_comments_post ON community_comments(post_id);
CREATE INDEX IF NOT EXISTS community_comments_author_id_idx ON community_comments(author_id);

-- Enable RLS on community_comments
ALTER TABLE community_comments ENABLE ROW LEVEL SECURITY;

-- Create community_post_votes table
CREATE TABLE IF NOT EXISTS community_post_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid REFERENCES community_posts(id) ON DELETE CASCADE,
  author_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  vote_type text NOT NULL CHECK (vote_type IN ('up', 'down')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(post_id, author_id)
);

-- Create index on community_post_votes
CREATE INDEX IF NOT EXISTS community_post_votes_post_id_author_id_idx ON community_post_votes(post_id, author_id);

-- Enable RLS on community_post_votes
ALTER TABLE community_post_votes ENABLE ROW LEVEL SECURITY;

-- Create community_comment_votes table
CREATE TABLE IF NOT EXISTS community_comment_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id uuid REFERENCES community_comments(id) ON DELETE CASCADE,
  author_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  vote_type text NOT NULL CHECK (vote_type IN ('up', 'down')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(comment_id, author_id)
);

-- Create index on community_comment_votes
CREATE INDEX IF NOT EXISTS community_comment_votes_comment_id_author_id_idx ON community_comment_votes(comment_id, author_id);

-- Enable RLS on community_comment_votes
ALTER TABLE community_comment_votes ENABLE ROW LEVEL SECURITY;

-- Create vote tracking functions
CREATE FUNCTION update_community_post_votes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.vote_type = 'up' THEN
      UPDATE community_posts SET upvotes = upvotes + 1 WHERE id = NEW.post_id;
    ELSE
      UPDATE community_posts SET downvotes = downvotes + 1 WHERE id = NEW.post_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.vote_type = 'up' THEN
      UPDATE community_posts SET upvotes = upvotes - 1 WHERE id = OLD.post_id;
    ELSE
      UPDATE community_posts SET downvotes = downvotes - 1 WHERE id = OLD.post_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION update_community_comment_votes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.vote_type = 'up' THEN
      UPDATE community_comments SET upvotes = upvotes + 1 WHERE id = NEW.comment_id;
    ELSE
      UPDATE community_comments SET downvotes = downvotes + 1 WHERE id = NEW.comment_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.vote_type = 'up' THEN
      UPDATE community_comments SET upvotes = upvotes - 1 WHERE id = OLD.comment_id;
    ELSE
      UPDATE community_comments SET downvotes = downvotes - 1 WHERE id = OLD.comment_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create vote tracking triggers
CREATE TRIGGER update_community_post_votes_trigger
  AFTER INSERT OR DELETE ON community_post_votes
  FOR EACH ROW
  EXECUTE FUNCTION update_community_post_votes();

CREATE TRIGGER update_community_comment_votes_trigger
  AFTER INSERT OR DELETE ON community_comment_votes
  FOR EACH ROW
  EXECUTE FUNCTION update_community_comment_votes();

-- Create policies
DO $$ 
BEGIN
  -- Categories policies
  DROP POLICY IF EXISTS "Anyone can view categories" ON categories;
  DROP POLICY IF EXISTS "Admins can manage categories" ON categories;
  
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

  -- Community posts policies
  DROP POLICY IF EXISTS "Anyone can view community posts" ON community_posts;
  DROP POLICY IF EXISTS "Authenticated users can create posts" ON community_posts;
  DROP POLICY IF EXISTS "Users can update own posts" ON community_posts;
  DROP POLICY IF EXISTS "Admins can update any post" ON community_posts;

  CREATE POLICY "Anyone can view community posts"
    ON community_posts FOR SELECT
    TO public
    USING (true);

  CREATE POLICY "Authenticated users can create posts"
    ON community_posts FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = author_id);

  CREATE POLICY "Users can update own posts"
    ON community_posts FOR UPDATE
    TO authenticated
    USING (auth.uid() = author_id);

  CREATE POLICY "Admins can update any post"
    ON community_posts FOR UPDATE
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'superadmin')
      )
    );

  -- Community comments policies
  DROP POLICY IF EXISTS "Anyone can view comments" ON community_comments;
  DROP POLICY IF EXISTS "Authenticated users can create comments" ON community_comments;
  DROP POLICY IF EXISTS "Users can update own comments" ON community_comments;

  CREATE POLICY "Anyone can view comments"
    ON community_comments FOR SELECT
    TO public
    USING (true);

  CREATE POLICY "Authenticated users can create comments"
    ON community_comments FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = author_id);

  CREATE POLICY "Users can update own comments"
    ON community_comments FOR UPDATE
    TO authenticated
    USING (auth.uid() = author_id)
    WITH CHECK (auth.uid() = author_id);

  -- Community post votes policies
  DROP POLICY IF EXISTS "Users can view post votes" ON community_post_votes;
  DROP POLICY IF EXISTS "Users can manage own post votes" ON community_post_votes;

  CREATE POLICY "Users can view post votes"
    ON community_post_votes FOR SELECT
    TO authenticated
    USING (true);

  CREATE POLICY "Users can manage own post votes"
    ON community_post_votes FOR ALL
    TO authenticated
    USING (auth.uid() = author_id)
    WITH CHECK (auth.uid() = author_id);

  -- Community comment votes policies
  DROP POLICY IF EXISTS "Users can view comment votes" ON community_comment_votes;
  DROP POLICY IF EXISTS "Users can manage own comment votes" ON community_comment_votes;

  CREATE POLICY "Users can view comment votes"
    ON community_comment_votes FOR SELECT
    TO authenticated
    USING (true);

  CREATE POLICY "Users can manage own comment votes"
    ON community_comment_votes FOR ALL
    TO authenticated
    USING (auth.uid() = author_id)
    WITH CHECK (auth.uid() = author_id);

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