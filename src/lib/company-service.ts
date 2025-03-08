import { supabase } from './supabase';

export interface CompanyProfile {
  id: string;
  name: string;
  description: string;
  mission: string;
  vision: string;
  industry: string;
  target_market: string;
  problem_statement: string;
  solution_overview: string;
  business_model: string;
  competitor_analysis: string;
  team_members: Array<{
    id: string;
    name: string;
    role: string;
    bio: string;
  }>;
  financial_highlights: string;
  funding_requirements?: string;
  created_at: string;
  updated_at: string;
  owner_id: string;
}

/**
 * Fetches company profile information for the current user
 * @param userId The user ID to fetch company data for
 * @returns Company profile data or null if not found
 */
export const fetchUserCompanyProfile = async (userId: string): Promise<CompanyProfile | null> => {
  try {
    // First, check if the user owns any company
    const { data: ownedCompany, error: ownedError } = await supabase
      .from('companies')
      .select('*')
      .eq('owner_id', userId)
      .single();

    if (ownedError && ownedError.code !== 'PGRST116') {
      // PGRST116 is "no rows returned" error, which is expected if user doesn't own a company
      throw ownedError;
    }

    if (ownedCompany) {
      // Fetch team members for this company
      const { data: teamMembers, error: teamError } = await supabase
        .from('company_members')
        .select('id, user_id, role, profiles(id, full_name, bio)')
        .eq('company_id', ownedCompany.id);

      if (teamError) throw teamError;

      // Format team members data
      const formattedTeamMembers = (teamMembers || []).map(member => ({
        id: member.id,
        name: member.profiles?.full_name || 'Team Member',
        role: member.role || 'Member',
        bio: member.profiles?.bio || ''
      }));

      // Return formatted company profile
      return {
        ...ownedCompany,
        team_members: formattedTeamMembers
      };
    }

    // If user doesn't own a company, check if they're a member of any company
    const { data: memberCompanies, error: memberError } = await supabase
      .from('company_members')
      .select('company_id')
      .eq('user_id', userId);

    if (memberError) throw memberError;

    if (memberCompanies && memberCompanies.length > 0) {
      // Get the first company they're a member of
      const { data: company, error: companyError } = await supabase
        .from('companies')
        .select('*')
        .eq('id', memberCompanies[0].company_id)
        .single();

      if (companyError) throw companyError;

      // Fetch team members for this company
      const { data: teamMembers, error: teamError } = await supabase
        .from('company_members')
        .select('id, user_id, role, profiles(id, full_name, bio)')
        .eq('company_id', company.id);

      if (teamError) throw teamError;

      // Format team members data
      const formattedTeamMembers = (teamMembers || []).map(member => ({
        id: member.id,
        name: member.profiles?.full_name || 'Team Member',
        role: member.role || 'Member',
        bio: member.profiles?.bio || ''
      }));

      // Return formatted company profile
      return {
        ...company,
        team_members: formattedTeamMembers
      };
    }

    // No company found
    return null;
  } catch (error) {
    console.error('Error fetching company profile:', error);
    throw error;
  }
};

/**
 * Maps company profile data to business info for pitch deck generation
 * @param company The company profile data
 * @returns Formatted business info for the pitch deck generator
 */
export const mapCompanyProfileToBusinessInfo = (company: CompanyProfile) => {
  // Format team members into a string for the pitch deck
  const teamInfo = company.team_members
    .map(member => `${member.name} - ${member.role}: ${member.bio}`)
    .join('\n');

  return {
    companyName: company.name,
    tagline: company.vision || company.description?.split('.')[0] || '',
    problem: company.problem_statement || '',
    solution: company.solution_overview || '',
    market: company.target_market || '',
    businessModel: company.business_model || '',
    competition: company.competitor_analysis || '',
    teamInfo: teamInfo,
    financials: company.financial_highlights || '',
    askAmount: company.funding_requirements || ''
  };
};

/**
 * Saves feedback and suggestions for a pitch deck
 * @param deckId The pitch deck ID
 * @param feedbackData The feedback and suggestions data
 * @returns The saved feedback record
 */
export const savePitchDeckFeedback = async (deckId: string, feedbackData: {
  suggestions: Array<{
    slideId: string;
    content: string;
    type: 'design' | 'content' | 'structure';
    applied: boolean;
  }>;
  overall_feedback: string;
  generated_by: 'ai' | 'user';
  user_id?: string;
}) => {
  try {
    const { data, error } = await supabase
      .from('pitch_deck_feedback')
      .insert({
        pitch_deck_id: deckId,
        suggestions: feedbackData.suggestions,
        overall_feedback: feedbackData.overall_feedback,
        generated_by: feedbackData.generated_by,
        user_id: feedbackData.user_id
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error saving pitch deck feedback:', error);
    throw error;
  }
};

/**
 * Fetches feedback and suggestions for a pitch deck
 * @param deckId The pitch deck ID
 * @returns Array of feedback records
 */
export const fetchPitchDeckFeedback = async (deckId: string) => {
  try {
    const { data, error } = await supabase
      .from('pitch_deck_feedback')
      .select('*')
      .eq('pitch_deck_id', deckId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error fetching pitch deck feedback:', error);
    throw error;
  }
}; 