/*
  # Document Management Schema

  1. New Tables
    - company_documents: Company document storage and organization
    - resource_library: Platform-wide resource management

  2. Security
    - RLS enabled on all tables
    - Role-based access for company documents
    - Premium content restrictions for resource library

  3. Features
    - Document organization with folders
    - File metadata tracking
    - Resource categorization
    - Premium content flagging
*/

-- Create company_documents table
CREATE TABLE IF NOT EXISTS company_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  file_url text NOT NULL,
  file_type text NOT NULL,
  size_bytes bigint,
  folder_path text DEFAULT '/',
  created_by uuid REFERENCES auth.users(id),
  last_modified_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create resource_library table
CREATE TABLE IF NOT EXISTS resource_library (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  category text NOT NULL,
  type text NOT NULL,
  content_url text NOT NULL,
  thumbnail_url text,
  tags text[] DEFAULT '{}'::text[],
  is_premium boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_company_documents_company ON company_documents(company_id);
CREATE INDEX IF NOT EXISTS resource_library_category_idx ON resource_library(category);
CREATE INDEX IF NOT EXISTS resource_library_type_idx ON resource_library(type);

-- Enable RLS
ALTER TABLE company_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_library ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Drop company documents policies
  DROP POLICY IF EXISTS "Company members can view documents" ON company_documents;
  DROP POLICY IF EXISTS "Company admins can manage documents" ON company_documents;
  
  -- Drop resource library policies
  DROP POLICY IF EXISTS "Anyone can view free resources" ON resource_library;
  DROP POLICY IF EXISTS "Premium users can view all resources" ON resource_library;
EXCEPTION
  WHEN undefined_object THEN
    NULL;
END $$;

-- Create policies
-- Company Documents
CREATE POLICY "Company members can view documents"
  ON company_documents FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_members
      WHERE company_id = company_documents.company_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Company admins can manage documents"
  ON company_documents FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_members
      WHERE company_id = company_documents.company_id
      AND user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM company_members
      WHERE company_id = company_documents.company_id
      AND user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );

-- Resource Library
CREATE POLICY "Anyone can view free resources"
  ON resource_library FOR SELECT
  TO public
  USING (NOT is_premium);

CREATE POLICY "Premium users can view all resources"
  ON resource_library FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND settings->'subscription'->>'status' = 'active'
    )
  );