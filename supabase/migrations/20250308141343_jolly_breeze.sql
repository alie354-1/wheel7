/*
  # Ideas and Variations Tables Migration

  1. New Tables
    - ideas: Stores main idea records with user associations
    - idea_variations: Stores variations of ideas with relationships
  
  2. Security
    - Enable RLS on both tables
    - Add policies for user access control
  
  3. Performance
    - Add indexes for common query patterns
*/

DO $$ 
BEGIN
  -- Create ideas table if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'ideas') THEN
    CREATE TABLE ideas (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
      title text NOT NULL,
      description text,
      problem_statement text,
      solution text,
      target_market text,
      status text DEFAULT 'draft',
      ai_feedback jsonb DEFAULT '{}',
      market_insights jsonb DEFAULT '{}',
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now()
    );

    -- Enable RLS
    ALTER TABLE ideas ENABLE ROW LEVEL SECURITY;

    -- Create policies for ideas
    CREATE POLICY "Users can manage their own ideas"
      ON ideas
      FOR ALL
      TO authenticated
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);

    -- Create indexes for ideas
    CREATE INDEX IF NOT EXISTS ideas_user_id_idx ON ideas(user_id);
    CREATE INDEX IF NOT EXISTS ideas_status_idx ON ideas(status);
    CREATE INDEX IF NOT EXISTS ideas_created_at_idx ON ideas(created_at);
  END IF;

  -- Create idea_variations table if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'idea_variations') THEN
    CREATE TABLE idea_variations (
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

    -- Enable RLS
    ALTER TABLE idea_variations ENABLE ROW LEVEL SECURITY;

    -- Create policies for idea variations
    CREATE POLICY "Users can manage their own idea variations"
      ON idea_variations
      FOR ALL
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM ideas
          WHERE ideas.id = idea_variations.idea_id
          AND ideas.user_id = auth.uid()
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM ideas
          WHERE ideas.id = idea_variations.idea_id
          AND ideas.user_id = auth.uid()
        )
      );

    -- Create index for idea variations
    CREATE INDEX IF NOT EXISTS idea_variations_idea_id_idx ON idea_variations(idea_id);
  END IF;
END $$;