-- Drop existing policies first
DO $$ BEGIN
    DROP POLICY IF EXISTS "Company members can view their own company members" ON company_members;
    DROP POLICY IF EXISTS "Company admins can manage members" ON company_members;
    DROP POLICY IF EXISTS "Company members can view documents" ON company_documents;
    DROP POLICY IF EXISTS "Company members can create documents" ON company_documents;
    DROP POLICY IF EXISTS "Document creators and admins can update documents" ON company_documents;
    DROP POLICY IF EXISTS "Company members can view tasks" ON company_tasks;
    DROP POLICY IF EXISTS "Company members can create and update tasks" ON company_tasks;
    DROP POLICY IF EXISTS "Company members can view development environments" ON development_environments;
    DROP POLICY IF EXISTS "Company admins can manage development environments" ON development_environments;
EXCEPTION
    WHEN undefined_object THEN null;
END $$;

-- Fix company_members table structure
ALTER TABLE company_members DROP CONSTRAINT IF EXISTS company_members_user_id_fkey;
ALTER TABLE company_members DROP CONSTRAINT IF EXISTS company_members_company_id_fkey;

-- Re-add proper foreign keys
ALTER TABLE company_members
  ADD CONSTRAINT company_members_user_id_fkey 
  FOREIGN KEY (user_id) 
  REFERENCES auth.users(id) 
  ON DELETE CASCADE;

ALTER TABLE company_members
  ADD CONSTRAINT company_members_company_id_fkey 
  FOREIGN KEY (company_id) 
  REFERENCES companies(id) 
  ON DELETE CASCADE;

-- Create simplified non-recursive policies
CREATE POLICY "member_view_policy"
  ON company_members
  FOR SELECT
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM companies
      WHERE id = company_members.company_id
      AND owner_id = auth.uid()
    )
  );

CREATE POLICY "member_manage_policy"
  ON company_members
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM companies
      WHERE id = company_members.company_id
      AND owner_id = auth.uid()
    )
  );

-- Document policies
CREATE POLICY "document_view_policy"
  ON company_documents
  FOR SELECT
  USING (
    created_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM companies
      WHERE id = company_documents.company_id
      AND (
        owner_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM company_members
          WHERE company_id = companies.id
          AND user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "document_create_policy"
  ON company_documents
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies
      WHERE id = company_documents.company_id
      AND (
        owner_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM company_members
          WHERE company_id = companies.id
          AND user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "document_update_policy"
  ON company_documents
  FOR UPDATE
  USING (
    created_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM companies
      WHERE id = company_documents.company_id
      AND owner_id = auth.uid()
    )
  );

-- Task policies
CREATE POLICY "task_view_policy"
  ON company_tasks
  FOR SELECT
  USING (
    created_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM companies
      WHERE id = company_tasks.company_id
      AND (
        owner_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM company_members
          WHERE company_id = companies.id
          AND user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "task_manage_policy"
  ON company_tasks
  FOR ALL
  USING (
    created_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM companies
      WHERE id = company_tasks.company_id
      AND (
        owner_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM company_members
          WHERE company_id = companies.id
          AND user_id = auth.uid()
        )
      )
    )
  );

-- Development environment policies
CREATE POLICY "environment_view_policy"
  ON development_environments
  FOR SELECT
  USING (
    created_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM companies
      WHERE id = development_environments.company_id
      AND (
        owner_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM company_members
          WHERE company_id = companies.id
          AND user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "environment_manage_policy"
  ON development_environments
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM companies
      WHERE id = development_environments.company_id
      AND owner_id = auth.uid()
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_members_user_id ON company_members(user_id);
CREATE INDEX IF NOT EXISTS idx_company_members_company_id ON company_members(company_id);
CREATE INDEX IF NOT EXISTS idx_company_documents_company_id ON company_documents(company_id);
CREATE INDEX IF NOT EXISTS idx_company_documents_created_by ON company_documents(created_by);
CREATE INDEX IF NOT EXISTS idx_company_tasks_company_id ON company_tasks(company_id);
CREATE INDEX IF NOT EXISTS idx_company_tasks_created_by ON company_tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_development_environments_company_id ON development_environments(company_id);
CREATE INDEX IF NOT EXISTS idx_development_environments_created_by ON development_environments(created_by);