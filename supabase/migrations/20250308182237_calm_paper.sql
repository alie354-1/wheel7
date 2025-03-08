/*
  # Add Sample Resources

  1. Purpose
    - Add initial set of resources for AI recommendations
    - Include mix of web, platform, and community resources
    - Cover different resource types and categories

  2. Resource Categories
    - Development Resources
    - Business Planning
    - Marketing & Growth
    - Design & UX
    - Project Management
    - Legal & Compliance

  3. Resource Types
    - Articles
    - Videos
    - Tools
    - Templates
    - Guides
*/

-- Insert web resources
INSERT INTO resources (title, description, url, type, source, is_public) VALUES
  (
    'Git Workflow Best Practices',
    'Comprehensive guide to Git workflows for teams',
    'https://www.atlassian.com/git/tutorials/comparing-workflows',
    'article',
    'web',
    true
  ),
  (
    'React Performance Optimization',
    'Learn how to optimize React applications',
    'https://reactjs.org/docs/optimizing-performance.html',
    'guide',
    'web',
    true
  ),
  (
    'Introduction to System Design',
    'System design concepts and best practices',
    'https://github.com/donnemartin/system-design-primer',
    'guide',
    'web',
    true
  ),
  (
    'Modern CSS Techniques',
    'Advanced CSS and layout patterns',
    'https://web.dev/learn/css/',
    'guide',
    'web',
    true
  );

-- Insert Wheel platform resources
INSERT INTO resources (title, description, url, type, source, is_public) VALUES
  (
    'Startup Financial Model Template',
    'Customizable financial model for startups',
    '/resources/templates/financial-model',
    'template',
    'wheel',
    true
  ),
  (
    'Product Requirements Document Template',
    'Comprehensive PRD template for product planning',
    '/resources/templates/prd-template',
    'template',
    'wheel',
    true
  ),
  (
    'Market Research Framework',
    'Step-by-step guide to market research',
    '/resources/guides/market-research',
    'guide',
    'wheel',
    true
  ),
  (
    'Pitch Deck Builder Tutorial',
    'Learn how to create compelling pitch decks',
    '/resources/tutorials/pitch-deck',
    'video',
    'wheel',
    true
  );

-- Insert community resources (with admin user as author)
WITH admin_user AS (
  SELECT id FROM profiles WHERE role = 'superadmin' LIMIT 1
)
INSERT INTO resources (title, description, url, type, source, author_id, is_public)
SELECT
  title,
  description,
  url,
  type,
  'community',
  (SELECT id FROM admin_user),
  true
FROM (
  VALUES
    (
      'API Security Checklist',
      'Comprehensive security checklist for API development',
      '/community/resources/api-security-checklist',
      'template'
    ),
    (
      'SaaS Pricing Strategy Guide',
      'Real-world examples and strategies for SaaS pricing',
      '/community/resources/saas-pricing-guide',
      'guide'
    ),
    (
      'Technical Due Diligence Template',
      'Template for conducting technical due diligence',
      '/community/resources/tech-dd-template',
      'template'
    ),
    (
      'Cloud Architecture Patterns',
      'Common patterns for cloud-native applications',
      '/community/resources/cloud-patterns',
      'article'
    )
) AS community_resources(title, description, url, type);

-- Create indexes for better search performance
CREATE INDEX IF NOT EXISTS resources_title_description_idx ON resources USING gin(to_tsvector('english', title || ' ' || description));
CREATE INDEX IF NOT EXISTS resources_is_public_idx ON resources(is_public) WHERE is_public = true;