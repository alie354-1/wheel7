-- Create companies table first
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  industries text[] DEFAULT '{}',
  website text,
  size text,
  stage text,
  founded_year integer,
  business_model text,
  target_market text,
  mission text,
  is_public boolean DEFAULT false,
  logo_url text,
  social_links jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Company Members Table
CREATE TABLE IF NOT EXISTS company_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'guest')),
  title text,
  department text,
  invited_email text,
  invitation_token uuid,
  joined_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, user_id)
);

-- Documents Table
CREATE TABLE IF NOT EXISTS company_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  folder_path text NOT NULL DEFAULT '/',
  file_type text NOT NULL,
  file_url text NOT NULL,
  size_bytes bigint,
  created_by uuid REFERENCES auth.users(id),
  last_modified_by uuid REFERENCES auth.users(id),
  is_archived boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tasks Table
CREATE TABLE IF NOT EXISTS company_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'blocked')),
  priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  due_date timestamptz,
  assigned_to uuid REFERENCES auth.users(id),
  created_by uuid REFERENCES auth.users(id),
  category text NOT NULL DEFAULT 'general',
  parent_task_id uuid REFERENCES company_tasks(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Development Environments Table
CREATE TABLE IF NOT EXISTS development_environments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  environment_type text NOT NULL CHECK (environment_type IN ('development', 'staging', 'production')),
  provider text NOT NULL,
  configuration jsonb NOT NULL DEFAULT '{}',
  status text NOT NULL DEFAULT 'inactive' CHECK (status IN ('inactive', 'provisioning', 'active', 'error')),
  created_by uuid REFERENCES auth.users(id),
  last_modified_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE development_environments ENABLE ROW LEVEL SECURITY;

-- Companies Policies
CREATE POLICY "Users can view their own companies"
  ON companies
  FOR SELECT
  USING (owner_id = auth.uid());

CREATE POLICY "Users can create their own companies"
  ON companies
  FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can update their own companies"
  ON companies
  FOR UPDATE
  USING (owner_id = auth.uid());

-- Company Members Policies
CREATE POLICY "Company members can view their own company members"
  ON company_members
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = company_members.company_id
      AND cm.user_id = auth.uid()
    )
  );

CREATE POLICY "Company admins can manage members"
  ON company_members
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = company_members.company_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  );

-- Documents Policies
CREATE POLICY "Company members can view documents"
  ON company_documents
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = company_documents.company_id
      AND cm.user_id = auth.uid()
    )
  );

CREATE POLICY "Company members can create documents"
  ON company_documents
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = company_documents.company_id
      AND cm.user_id = auth.uid()
    )
  );

CREATE POLICY "Document creators and admins can update documents"
  ON company_documents
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = company_documents.company_id
      AND cm.user_id = auth.uid()
      AND (cm.role IN ('owner', 'admin') OR auth.uid() = company_documents.created_by)
    )
  );

-- Tasks Policies
CREATE POLICY "Company members can view tasks"
  ON company_tasks
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = company_tasks.company_id
      AND cm.user_id = auth.uid()
    )
  );

CREATE POLICY "Company members can create and update tasks"
  ON company_tasks
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = company_tasks.company_id
      AND cm.user_id = auth.uid()
    )
  );

-- Development Environments Policies
CREATE POLICY "Company members can view development environments"
  ON development_environments
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = development_environments.company_id
      AND cm.user_id = auth.uid()
    )
  );

CREATE POLICY "Company admins can manage development environments"
  ON development_environments
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM company_members cm
      WHERE cm.company_id = development_environments.company_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('owner', 'admin')
    )
  );

-- Helper Functions
CREATE OR REPLACE FUNCTION is_company_member(company_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM company_members
    WHERE company_id = $1
    AND user_id = auth.uid()
  );
END;
$$;

CREATE OR REPLACE FUNCTION is_company_admin(company_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM company_members
    WHERE company_id = $1
    AND user_id = auth.uid()
    AND role IN ('owner', 'admin')
  );
END;
$$;

-- Create indexes for better performance
CREATE INDEX idx_companies_owner_id ON companies(owner_id);
CREATE INDEX idx_company_members_company_id ON company_members(company_id);
CREATE INDEX idx_company_members_user_id ON company_members(user_id);
CREATE INDEX idx_company_documents_company_id ON company_documents(company_id);
CREATE INDEX idx_company_documents_created_by ON company_documents(created_by);
CREATE INDEX idx_company_tasks_company_id ON company_tasks(company_id);
CREATE INDEX idx_company_tasks_assigned_to ON company_tasks(assigned_to);
CREATE INDEX idx_development_environments_company_id ON development_environments(company_id);