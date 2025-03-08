/*
  # Community Features Setup

  1. New Tables
    - community_posts: For storing community discussions and posts
    - community_comments: For post comments and replies
    - community_post_votes: For tracking post upvotes/downvotes
    - community_comment_votes: For tracking comment upvotes/downvotes

  2. Security
    - Enable RLS on all tables
    - Add policies for access control
    
  3. Functions & Triggers
    - Vote tracking functions
    - Automatic vote count updates
*/

-- Create community_posts table
CREATE TABLE IF NOT EXISTS community_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  content text NOT NULL,
  category_id uuid REFERENCES categories(id) ON DELETE SET NULL,
  tags text[] DEFAULT '{}',
  upvotes integer DEFAULT 0,
  downvotes integer DEFAULT 0,
  is_pinned boolean DEFAULT false,
  is_locked boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes on community_posts
CREATE INDEX IF NOT EXISTS community_posts_author_id_idx ON community_posts(author_id);
CREATE INDEX IF NOT EXISTS community_posts_category_id_idx ON community_posts(category_id);
CREATE INDEX IF NOT EXISTS community_posts_created_at_idx ON community_posts(created_at);

-- Enable RLS on community_posts
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;

-- Create community_comments table first without parent_id
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

-- Add parent_id column after table creation
ALTER TABLE community_comments 
ADD COLUMN IF NOT EXISTS parent_id uuid REFERENCES community_comments(id) ON DELETE CASCADE;

-- Create indexes on community_comments
CREATE INDEX IF NOT EXISTS community_comments_post_id_idx ON community_comments(post_id);
CREATE INDEX IF NOT EXISTS community_comments_author_id_idx ON community_comments(author_id);
CREATE INDEX IF NOT EXISTS community_comments_parent_id_idx ON community_comments(parent_id);

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
CREATE OR REPLACE FUNCTION update_community_post_votes()
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

CREATE OR REPLACE FUNCTION update_community_comment_votes()
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
DROP TRIGGER IF EXISTS update_community_post_votes_trigger ON community_post_votes;
DROP TRIGGER IF EXISTS update_community_comment_votes_trigger ON community_comment_votes;

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
  -- Community posts policies
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
  CREATE POLICY "Users can view comment votes"
    ON community_comment_votes FOR SELECT
    TO authenticated
    USING (true);

  CREATE POLICY "Users can manage own comment votes"
    ON community_comment_votes FOR ALL
    TO authenticated
    USING (auth.uid() = author_id)
    WITH CHECK (auth.uid() = author_id);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;