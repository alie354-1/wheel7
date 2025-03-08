/*
  # Core Schema Migration

  1. Tables
    - Core business tables for companies, ideas, and business models
    - Settings and configuration tables
    - Trigger functions for automation

  2. Features
    - Full company management
    - Idea tracking and variations
    - Business modeling
    - Settings management

  3. Security
    - RLS enabled on all tables
    - Role-based access control
    - Secure defaults
*/

-- Create core tables
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  industries text[],
  website text,
  size text,
  stage text,
  business_model text,
  target_market text,
  is_public boolean DEFAULT false,
  logo_url text,
  social_links jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS company_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'guest')),
  title text,
  department text,
  invited_email text,
  invitation_token uuid,
  joined_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, user_id)
);

CREATE TABLE IF NOT EXISTS ideas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  problem_statement text,
  solution text,
  target_market text,
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'exploring', 'validated', 'archived')),
  ai_feedback jsonb DEFAULT '{}'::jsonb,
  market_insights jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS idea_variations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  idea_id uuid REFERENCES ideas(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  differentiator text,
  target_market text,
  revenue_model text,
  liked_aspects text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS idea_canvases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  sections jsonb NOT NULL,
  is_public boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS market_research (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  insights jsonb,
  competitors jsonb,
  notes text,
  is_public boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS business_models (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  revenue_streams jsonb DEFAULT '[]'::jsonb,
  cost_structure jsonb DEFAULT '[]'::jsonb,
  key_metrics jsonb DEFAULT '[]'::jsonb,
  financial_projections jsonb DEFAULT '{}'::jsonb,
  is_public boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pitch_decks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  slides jsonb DEFAULT '[]'::jsonb,
  theme text DEFAULT 'default',
  is_public boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

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

CREATE TABLE IF NOT EXISTS app_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE CHECK (key IN ('openai', 'app_credentials', 'feature_flags')),
  value jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS slack_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id text NOT NULL,
  bot_token text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_companies_owner ON companies(owner_id);
CREATE INDEX IF NOT EXISTS idx_company_members_company ON company_members(company_id);
CREATE INDEX IF NOT EXISTS idx_company_members_user ON company_members(user_id);

CREATE INDEX IF NOT EXISTS ideas_user_id_idx ON ideas(user_id);
CREATE INDEX IF NOT EXISTS ideas_status_idx ON ideas(status);
CREATE INDEX IF NOT EXISTS ideas_created_at_idx ON ideas(created_at);

CREATE INDEX IF NOT EXISTS idea_variations_idea_id_idx ON idea_variations(idea_id);
CREATE INDEX IF NOT EXISTS categories_slug_idx ON categories(slug);

-- Enable RLS
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE ideas ENABLE ROW LEVEL SECURITY;
ALTER TABLE idea_variations ENABLE ROW LEVEL SECURITY;
ALTER TABLE idea_canvases ENABLE ROW LEVEL SECURITY;
ALTER TABLE market_research ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE pitch_decks ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE slack_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Ideas
  DROP POLICY IF EXISTS "Users can manage their own ideas" ON ideas;
  
  -- Idea Variations
  DROP POLICY IF EXISTS "Users can manage their own idea variations" ON idea_variations;
  
  -- Categories
  DROP POLICY IF EXISTS "Anyone can view categories" ON categories;
  DROP POLICY IF EXISTS "Admins can manage categories" ON categories;
  
  -- App Settings
  DROP POLICY IF EXISTS "Admins can manage app settings" ON app_settings;
  DROP POLICY IF EXISTS "Anyone can view app settings" ON app_settings;
EXCEPTION
  WHEN undefined_object THEN NULL;
END $$;

-- Create policies
-- Ideas
CREATE POLICY "Users can manage their own ideas"
  ON ideas FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Idea Variations
CREATE POLICY "Users can manage their own idea variations"
  ON idea_variations FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM ideas
    WHERE ideas.id = idea_variations.idea_id
    AND ideas.user_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM ideas
    WHERE ideas.id = idea_variations.idea_id
    AND ideas.user_id = auth.uid()
  ));

-- Categories
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

-- App Settings
CREATE POLICY "Admins can manage app settings"
  ON app_settings FOR ALL
  TO public
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'superadmin')
    )
  );

CREATE POLICY "Anyone can view app settings"
  ON app_settings FOR SELECT
  TO public
  USING (true);