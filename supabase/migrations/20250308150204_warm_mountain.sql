/*
  # Community Features Schema

  1. Tables
    - communities: Community management
    - community_members: Member relationships
    - community_posts: Discussion posts
    - community_comments: Post comments
    - community_post_votes: Post voting
    - community_comment_votes: Comment voting

  2. Features
    - Full community management
    - Member roles and permissions
    - Discussion system
    - Voting system
    - Comment threading

  3. Security
    - RLS enabled on all tables
    - Role-based access control
    - Secure voting system
*/

-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Communities
  DROP POLICY IF EXISTS "Anyone can view communities" ON communities;
  DROP POLICY IF EXISTS "Admins can manage communities" ON communities;
  
  -- Community Members
  DROP POLICY IF EXISTS "Users can view community members" ON community_members;
  
  -- Community Posts
  DROP POLICY IF EXISTS "Anyone can view community posts" ON community_posts;
  DROP POLICY IF EXISTS "Authenticated users can create posts" ON community_posts;
  DROP POLICY IF EXISTS "Users can update own posts" ON community_posts;
  DROP POLICY IF EXISTS "Admins can update any post" ON community_posts;
  
  -- Community Comments
  DROP POLICY IF EXISTS "Anyone can view comments" ON community_comments;
  DROP POLICY IF EXISTS "Authenticated users can create comments" ON community_comments;
  DROP POLICY IF EXISTS "Users can update own comments" ON community_comments;
  
  -- Post Votes
  DROP POLICY IF EXISTS "Users can manage own post votes" ON community_post_votes;
  DROP POLICY IF EXISTS "Users can view post votes" ON community_post_votes;
  
  -- Comment Votes
  DROP POLICY IF EXISTS "Users can manage own comment votes" ON community_comment_votes;
  DROP POLICY IF EXISTS "Users can view comment votes" ON community_comment_votes;
EXCEPTION
  WHEN undefined_object THEN NULL;
END $$;

-- Create communities table
CREATE TABLE IF NOT EXISTS communities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  slug text NOT NULL UNIQUE,
  avatar_url text,
  banner_url text,
  member_count integer DEFAULT 0,
  is_private boolean DEFAULT false,
  owner_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create community_members table
CREATE TABLE IF NOT EXISTS community_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id uuid REFERENCES communities(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('owner', 'admin', 'moderator', 'member')),
  joined_at timestamptz DEFAULT now(),
  UNIQUE(community_id, user_id)
);

-- Create community_posts table
CREATE TABLE IF NOT EXISTS community_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id uuid REFERENCES communities(id) ON DELETE CASCADE,
  author_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  content text NOT NULL,
  post_type text DEFAULT 'discussion' NOT NULL,
  upvotes integer DEFAULT 0,
  downvotes integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  category_id uuid REFERENCES categories(id) ON DELETE SET NULL
);

-- Create community_comments table
CREATE TABLE IF NOT EXISTS community_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid REFERENCES community_posts(id) ON DELETE CASCADE,
  author_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  content text NOT NULL,
  upvotes integer DEFAULT 0,
  downvotes integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  parent_id uuid REFERENCES community_comments(id) ON DELETE CASCADE
);

-- Create community_post_votes table
CREATE TABLE IF NOT EXISTS community_post_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid REFERENCES community_posts(id) ON DELETE CASCADE,
  author_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  vote_type text NOT NULL CHECK (vote_type IN ('up', 'down')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(post_id, author_id)
);

-- Create community_comment_votes table
CREATE TABLE IF NOT EXISTS community_comment_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id uuid REFERENCES community_comments(id) ON DELETE CASCADE,
  author_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  vote_type text NOT NULL CHECK (vote_type IN ('up', 'down')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(comment_id, author_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_communities_slug ON communities(slug);
CREATE INDEX IF NOT EXISTS idx_community_members_community ON community_members(community_id);
CREATE INDEX IF NOT EXISTS idx_community_posts_community ON community_posts(community_id);
CREATE INDEX IF NOT EXISTS community_posts_author_id_idx ON community_posts(author_id);
CREATE INDEX IF NOT EXISTS community_posts_category_id_idx ON community_posts(category_id);
CREATE INDEX IF NOT EXISTS community_posts_created_at_idx ON community_posts(created_at);
CREATE INDEX IF NOT EXISTS community_comments_post_id_idx ON community_comments(post_id);
CREATE INDEX IF NOT EXISTS community_comments_author_id_idx ON community_comments(author_id);
CREATE INDEX IF NOT EXISTS community_comments_parent_id_idx ON community_comments(parent_id);

-- Enable RLS
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_post_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_comment_votes ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Communities
CREATE POLICY "Anyone can view communities"
  ON communities FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Admins can manage communities"
  ON communities FOR ALL
  TO public
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superadmin')
    )
  );

-- Community Members
CREATE POLICY "Users can view community members"
  ON community_members FOR SELECT
  TO authenticated
  USING (true);

-- Community Posts
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
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

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

-- Community Comments
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

-- Post Votes
CREATE POLICY "Users can manage own post votes"
  ON community_post_votes FOR ALL
  TO authenticated
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can view post votes"
  ON community_post_votes FOR SELECT
  TO authenticated
  USING (true);

-- Comment Votes
CREATE POLICY "Users can manage own comment votes"
  ON community_comment_votes FOR ALL
  TO authenticated
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can view comment votes"
  ON community_comment_votes FOR SELECT
  TO authenticated
  USING (true);