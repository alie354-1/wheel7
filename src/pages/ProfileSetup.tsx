import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  User, 
  Plus, 
  Briefcase, 
  Globe, 
  Link as LinkIcon,
  Mail,
  Building2,
  GraduationCap,
  Target,
  ArrowRight,
  ArrowLeft,
  Check,
  X,
  Settings,
  Save
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../lib/store';
import CloudStorageSetup from '../components/CloudStorageSetup';

const SETUP_STEPS = [
  { id: 'basic', name: 'Basic Info', description: 'Your name and contact details' },
  { id: 'professional', name: 'Professional', description: 'Your work experience' },
  { id: 'expertise', name: 'Expertise', description: 'Skills and interests' },
  { id: 'preferences', name: 'Preferences', description: 'Privacy and notifications' },
  { id: 'integrations', name: 'Integrations', description: 'Connect your accounts' }
];

const SUGGESTED_SKILLS = [
  'Product Management',
  'Software Development',
  'UI/UX Design',
  'Marketing',
  'Sales',
  'Business Development',
  'Data Analysis',
  'Project Management',
  'Leadership',
  'Strategy',
  'Finance',
  'Operations',
  'Customer Success',
  'Content Creation',
  'Growth Hacking'
];

const SUGGESTED_INTERESTS = [
  'Artificial Intelligence',
  'Blockchain',
  'E-commerce',
  'FinTech',
  'Healthcare',
  'SaaS',
  'Sustainability',
  'EdTech',
  'Mobile Apps',
  'IoT',
  'Cybersecurity',
  'Cloud Computing',
  'Digital Marketing',
  'Remote Work',
  'Social Impact'
];

interface FormData {
  // Basic Info
  full_name: string;
  headline: string;
  bio: string;
  location: string;
  timezone: string;
  languages: string[];

  // Professional Background
  professional_background: string;
  current_role: string;
  company: string;
  industry_experience: string[];
  education: Array<{
    degree: string;
    school: string;
    year: string;
  }>;

  // Expertise
  skills: string[];
  interests: string[];
  achievements: string[];
  looking_for: string[];

  // Preferences
  is_public: boolean;
  allows_messages: boolean;
  availability_status: 'full-time' | 'part-time' | 'weekends' | 'evenings' | 'not-available';
  mentor_preferences: {
    willing_to_mentor: boolean;
    seeking_mentor: boolean;
    areas_of_expertise: string[];
    areas_of_interest: string[];
  };

  // Social Links
  social_links: {
    linkedin: string;
    twitter: string;
    github: string;
    website: string;
  };
}

export default function ProfileSetup() {
  const navigate = useNavigate();
  const { user, profile, fetchProfile, updateSetupProgress } = useAuthStore();
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState('');
  const [currentStep, setCurrentStep] = useState('basic');
  const [formData, setFormData] = useState<FormData>(() => {
    // Try to load saved data from profile
    const savedData = profile?.setup_progress?.form_data;
    const defaultData: FormData = {
      // Basic Info
      full_name: '',
      headline: '',
      bio: '',
      location: '',
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      languages: ['English'],

      // Professional Background
      professional_background: '',
      current_role: '',
      company: '',
      industry_experience: [],
      education: [],

      // Expertise
      skills: [],
      interests: [],
      achievements: [],
      looking_for: [],

      // Preferences
      is_public: true,
      allows_messages: true,
      availability_status: 'part-time',
      mentor_preferences: {
        willing_to_mentor: false,
        seeking_mentor: false,
        areas_of_expertise: [],
        areas_of_interest: []
      },

      // Social Links
      social_links: {
        linkedin: '',
        twitter: '',
        github: '',
        website: ''
      }
    };

    if (savedData) {
      return {
        ...defaultData,
        ...savedData
      };
    }

    return defaultData;
  });

  useEffect(() => {
    if (!user) {
      navigate('/login');
      return;
    }

    // Load saved progress
    if (profile?.setup_progress) {
      setCurrentStep(profile.setup_progress.current_step || 'basic');
    }

    setIsLoading(false);
  }, [user, profile]);

  // Save progress when form data or current step changes
  useEffect(() => {
    const saveProgress = async () => {
      if (!user) return;

      try {
        await updateSetupProgress({
          current_step: currentStep,
          completed_steps: SETUP_STEPS
            .slice(0, SETUP_STEPS.findIndex(s => s.id === currentStep))
            .map(s => s.id),
          form_data: formData
        });
      } catch (error) {
        console.error('Error saving progress:', error);
      }
    };

    saveProgress();
  }, [formData, currentStep, user]);

  const handleInputChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    const { name, value, type } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? (e.target as HTMLInputElement).checked : value
    }));
  };

  const handleArrayInput = (field: keyof FormData, value: string) => {
    if (!value.trim()) return;
    setFormData(prev => ({
      ...prev,
      [field]: [...(prev[field] as string[]), value.trim()]
    }));
  };

  const removeArrayItem = (field: keyof FormData, index: number) => {
    setFormData(prev => ({
      ...prev,
      [field]: (prev[field] as any[]).filter((_, i) => i !== index)
    }));
  };

  const handleSocialLinkChange = (platform: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      social_links: {
        ...prev.social_links,
        [platform]: value
      }
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || !formData.full_name) return;

    setIsSaving(true);
    setError('');
    
    try {
      const { error } = await supabase
        .from('profiles')
        .update({
          ...formData,
          setup_progress: null, // Clear setup progress
          updated_at: new Date().toISOString()
        })
        .eq('id', user.id);

      if (error) throw error;

      await fetchProfile(user.id);
      navigate('/dashboard');
    } catch (error: any) {
      console.error('Error updating profile:', error);
      setError(error.message);
    } finally {
      setIsSaving(false);
    }
  };

  const handleSaveAndExit = async () => {
    if (!user || !formData.full_name.trim()) {
      setError('Full name is required');
      return;
    }

    setIsSaving(true);
    setError('');
    
    try {
      const { error } = await supabase
        .from('profiles')
        .update({
          full_name: formData.full_name,
          setup_progress: {
            current_step: currentStep,
            completed_steps: SETUP_STEPS
              .slice(0, SETUP_STEPS.findIndex(s => s.id === currentStep))
              .map(s => s.id),
            form_data: formData
          },
          updated_at: new Date().toISOString()
        })
        .eq('id', user.id);

      if (error) throw error;

      await fetchProfile(user.id);
      navigate('/dashboard');
    } catch (error: any) {
      console.error('Error saving profile:', error);
      setError(error.message);
    } finally {
      setIsSaving(false);
    }
  };

  const handleNext = () => {
    const currentIndex = SETUP_STEPS.findIndex(step => step.id === currentStep);
    if (currentIndex < SETUP_STEPS.length - 1) {
      setCurrentStep(SETUP_STEPS[currentIndex + 1].id);
    }
  };

  const handleBack = () => {
    const currentIndex = SETUP_STEPS.findIndex(step => step.id === currentStep);
    if (currentIndex > 0) {
      setCurrentStep(SETUP_STEPS[currentIndex - 1].id);
    }
  };

  const renderStepContent = () => {
    switch (currentStep) {
      case 'basic':
        return (
          <div className="space-y-6">
            <div>
              <label htmlFor="full_name" className="block text-sm font-medium text-gray-700">
                Full Name <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                id="full_name"
                name="full_name"
                value={formData.full_name}
                onChange={handleInputChange}
                required
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              />
            </div>

            <div>
              <label htmlFor="headline" className="block text-sm font-medium text-gray-700">
                Professional Headline
              </label>
              <input
                type="text"
                id="headline"
                name="headline"
                value={formData.headline}
                onChange={handleInputChange}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                placeholder="e.g., Founder & CEO | Tech Entrepreneur"
              />
            </div>

            <div>
              <label htmlFor="bio" className="block text-sm font-medium text-gray-700">
                Bio
              </label>
              <textarea
                id="bio"
                name="bio"
                rows={4}
                value={formData.bio}
                onChange={handleInputChange}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                placeholder="Tell us about yourself..."
              />
            </div>

            <div>
              <label htmlFor="location" className="block text-sm font-medium text-gray-700">
                Location
              </label>
              <input
                type="text"
                id="location"
                name="location"
                value={formData.location}
                onChange={handleInputChange}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                placeholder="City, Country"
              />
            </div>
          </div>
        );

      case 'professional':
        return (
          <div className="space-y-6">
            <div>
              <label htmlFor="professional_background" className="block text-sm font-medium text-gray-700">
                Professional Background
              </label>
              <textarea
                id="professional_background"
                name="professional_background"
                rows={4}
                value={formData.professional_background}
                onChange={handleInputChange}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                placeholder="Describe your professional experience..."
              />
            </div>

            <div>
              <label htmlFor="current_role" className="block text-sm font-medium text-gray-700">
                Current Role
              </label>
              <input
                type="text"
                id="current_role"
                name="current_role"
                value={formData.current_role}
                onChange={handleInputChange}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              />
            </div>

            <div>
              <label htmlFor="company" className="block text-sm font-medium text-gray-700">
                Company
              </label>
              <input
                type="text"
                id="company"
                name="company"
                value={formData.company}
                onChange={handleInputChange}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">
                Industry Experience
              </label>
              <div className="mt-2 flex flex-wrap gap-2">
                {formData.industry_experience.map((industry, index) => (
                  <span
                    key={index}
                    className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                  >
                    {industry}
                    <button
                      type="button"
                      onClick={() => removeArrayItem('industry_experience', index)}
                      className="ml-1.5 inline-flex items-center justify-center h-4 w-4 rounded-full text-blue-400 hover:bg-blue-200 hover:text-blue-500"
                    >
                      <X className="h-3 w-3" />
                    </button>
                  </span>
                ))}
              </div>
              <input
                type="text"
                placeholder="Add industry experience..."
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault();
                    handleArrayInput('industry_experience', e.currentTarget.value);
                    e.currentTarget.value = '';
                  }
                }}
                className="mt-2 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              />
            </div>
          </div>
        );

      case 'expertise':
        return (
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Skills
              </label>
              <div className="mt-2 flex flex-wrap gap-2">
                {formData.skills.map((skill, index) => (
                  <span
                    key={index}
                    className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800"
                  >
                    {skill}
                    <button
                      type="button"
                      onClick={() => removeArrayItem('skills', index)}
                      className="ml-1.5 inline-flex items-center justify-center h-4 w-4 rounded-full text-indigo-400 hover:bg-indigo-200 hover:text-indigo-500"
                    >
                      <X className="h-3 w-3" />
                    </button>
                  </span>
                ))}
              </div>
              <div className="mt-2">
                <input
                  type="text"
                  placeholder="Add a skill..."
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      handleArrayInput('skills', e.currentTarget.value);
                      e.currentTarget.value = '';
                    }
                  }}
                  className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
                <div className="mt-2 flex flex-wrap gap-2">
                  {SUGGESTED_SKILLS.map((skill) => (
                    <button
                      key={skill}
                      type="button"
                      onClick={() => handleArrayInput('skills', skill)}
                      className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 hover:bg-gray-200"
                    >
                      <Plus className="h-3 w-3 mr-1" />
                      {skill}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">
                Interests
              </label>
              <div className="mt-2 flex flex-wrap gap-2">
                {formData.interests.map((interest, index) => (
                  <span
                    key={index}
                    className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
                  >
                    {interest}
                    <button
                      type="button"
                      onClick={() => removeArrayItem('interests', index)}
                      className="ml-1.5 inline-flex items-center justify-center h-4 w-4 rounded-full text-green-400 hover:bg-green-200 hover:text-green-500"
                    >
                      <X className="h-3 w-3" />
                    </button>
                  </span>
                ))}
              </div>
              <div className="mt-2">
                <input
                  type="text"
                  placeholder="Add an interest..."
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      handleArrayInput('interests', e.currentTarget.value);
                      e.currentTarget.value = '';
                    }
                  }}
                  className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
                <div className="mt-2 flex flex-wrap gap-2">
                  {SUGGESTED_INTERESTS.map((interest) => (
                    <button
                      key={interest}
                      type="button"
                      onClick={() => handleArrayInput('interests', interest)}
                      className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 hover:bg-gray-200"
                    >
                      <Plus className="h-3 w-3 mr-1" />
                      {interest}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        );

      case 'preferences':
        return (
          <div className="space-y-6">
            <div>
              <label htmlFor="availability_status" className="block text-sm font-medium text-gray-700">
                Availability Status
              </label>
              <select
                id="availability_status"
                name="availability_status"
                value={formData.availability_status}
                onChange={handleInputChange}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              >
                <option value="full-time">Full-time</option>
                <option value="part-time">Part-time</option>
                <option value="weekends">Weekends</option>
                <option value="evenings">Evenings</option>
                <option value="not-available">Not Available</option>
              </select>
            </div>

            <div className="space-y-4">
              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="is_public"
                  name="is_public"
                  checked={formData.is_public}
                  onChange={handleInputChange}
                  className="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
                <label htmlFor="is_public" className="ml-2 block text-sm text-gray-900">
                  Make my profile public
                </label>
              </div>

              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="allows_messages"
                  name="allows_messages"
                  checked={formData.allows_messages}
                  onChange={handleInputChange}
                  className="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                />
                <label htmlFor="allows_messages" className="ml-2 block text-sm text-gray-900">
                  Allow other users to message me
                </label>
              </div>
            </div>
          </div>
        );

      case 'integrations':
        return (
          <div className="space-y-6">
            <div>
              <h3 className="text-lg font-medium text-gray-900">Social Links</h3>
              <div className="mt-2 space-y-4">
                <div>
                  <label htmlFor="linkedin" className="block text-sm font-medium text-gray-700">
                    LinkedIn
                  </label>
                  <div className="mt-1 relative rounded-md shadow-sm">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <LinkIcon className="h-5 w-5 text-gray-400" />
                    </div>
                    <input
                      type="url"
                      id="linkedin"
                      name="social_links.linkedin"
                      value={formData.social_links.linkedin}
                      onChange={(e) => handleSocialLinkChange('linkedin', e.target.value)}
                      className="block w-full pl-10 sm:text-sm border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                      placeholder="https://linkedin.com/in/username"
                    />
                  </div>
                </div>

                <div>
                  <label htmlFor="twitter" className="block text-sm font-medium text-gray-700">
                    Twitter
                  </label>
                  <div className="mt-1 relative rounded-md shadow-sm">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <LinkIcon className="h-5 w-5 text-gray-400" />
                    </div>
                    <input
                      type="url"
                      id="twitter"
                      name="social_links.twitter"
                      value={formData.social_links.twitter}
                      onChange={(e) => handleSocialLinkChange('twitter', e.target.value)}
                      className="block w-full pl-10 sm:text-sm border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                      placeholder="https://twitter.com/username"
                    />
                  </div>
                </div>

                <div>
                  <label htmlFor="github" className="block text-sm font-medium text-gray-700">
                    GitHub
                  </label>
                  <div className="mt-1 relative rounded-md shadow-sm">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <LinkIcon className="h-5 w-5 text-gray-400" />
                    </div>
                    <input
                      type="url"
                      id="github"
                      name="social_links.github"
                      value={formData.social_links.github}
                      onChange={(e) => handleSocialLinkChange('github', e.target.value)}
                      className="block w-full pl-10 sm:text-sm border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                      placeholder="https://github.com/username"
                    />
                  </div>
                </div>

                <div>
                  <label htmlFor="website" className="block text-sm font-medium text-gray-700">
                    Personal Website
                  </label>
                  <div className="mt-1 relative rounded-md shadow-sm">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <Globe className="h-5 w-5 text-gray-400" />
                    </div>
                    <input
                      type="url"
                      id="website"
                      name="social_links.website"
                      value={formData.social_links.website}
                      onChange={(e) => handleSocialLinkChange('website', e.target.value)}
                      className="block w-full pl-10 sm:text-sm border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                      placeholder="https://example.com"
                    />
                  </div>
                </div>
              </div>
            </div>

            <div>
              <h3 className="text-lg font-medium text-gray-900">Cloud Storage</h3>
              <div className="mt-2">
                <CloudStorageSetup />
              </div>
            </div>
          </div>
        );

      default:
        return null;
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-sm text-gray-600">Loading your profile...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-2xl mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <User className="mx-auto h-12 w-12 text-indigo-600" />
          <h2 className="mt-6 text-3xl font-extrabold text-gray-900">
            Complete Your Profile
          </h2>
          <p className="mt-2 text-sm text-gray-600">
            Let's get your profile set up so you can make the most of the platform
          </p>
        </div>

        {/* Save & Exit Button - Top */}
        <div className="mb-8 flex justify-end">
          <button
            onClick={handleSaveAndExit}
            disabled={!formData.full_name.trim() || isSaving}
            className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
          >
            <Save className="h-4 w-4 mr-2" />
            {isSaving ? 'Saving...' : 'Save & Exit'}
          </button>
        </div>

        {/* Progress Steps */}
        <nav aria-label="Progress" className="mb-8">
          <ol className="flex items-center">
            {SETUP_STEPS.map((step, stepIdx) => (
              <li
                key={step.id}
                className={`${stepIdx !== SETUP_STEPS.length - 1 ? 'flex-1' : ''} relative`}
              >
                <div className="group flex flex-col items-center">
                  <span className="flex items-center justify-center">
                    <span
                      className={`h-8 w-8 rounded-full flex items-center justify-center ${
                        stepIdx < SETUP_STEPS.findIndex(s => s.id === currentStep)
                          ? 'bg-indigo-600'
                          : currentStep === step.id
                          ? 'border-2 border-indigo-600 bg-white'
                          : 'border-2 border-gray-300 bg-white'
                      }`}
                    >
                      {stepIdx < SETUP_STEPS.findIndex(s => s.id === currentStep) ? (
                        <Check className="h-5 w-5 text-white" />
                      ) : (
                        <span className={`text-sm font-medium ${
                          currentStep === step.id ? 'text-indigo-600' : 'text-gray-500'
                        }`}>
                          {stepIdx + 1}
                        </span>
                      )}
                    </span>
                  </span>
                  {stepIdx !== SETUP_STEPS.length - 1 && (
                    <div
                      className={`hidden md:block absolute top-4 left-1/2 w-full h-0.5 transition-colors duration-150 ease-in-out ${
                        stepIdx < SETUP_STEPS.findIndex(s => s.id === currentStep)
                          ? 'bg-indigo-600'
                          : 'bg-gray-300'
                      }`}
                    />
                  )}
                  
                  {/* Step Content */}
                  <div className="mt-4 text-center">
                    <h3 className="text-sm font-medium text-gray-900">
                      {step.name}
                    </h3>
                    <p className="mt-1 text-xs text-gray-500">
                      {step.description}
                    </p>
                  </div>
                </div>
              </li>
            ))}
          </ol>
        </nav>

        {/* Form */}
        <div className="bg-white shadow rounded-lg p-6">
          {error && (
            <div className="mb-6 rounded-md bg-red-50 p-4">
              <div className="flex">
                <div className="flex-shrink-0">
                  <X className="h-5 w-5 text-red-400" />
                </div>
                <div className="ml-3 flex-1">
                  <p className="text-sm text-red-700">{error}</p>
                </div>
              </div>
            </div>
          )}

          {renderStepContent()}

          {/* Navigation */}
          <div className="mt-8 flex justify-between pt-6 border-t border-gray-200">
            <div className="flex space-x-3">
              <button 
                type="button"
                onClick={handleBack}
                disabled={currentStep === SETUP_STEPS[0].id}
                className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50"
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Back
              </button>
            </div>
            <div className="flex space-x-3">
              {currentStep !== SETUP_STEPS[SETUP_STEPS.length - 1].id ? (
                <button
                  type="button"
                  onClick={handleNext}
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                >
                  Next
                  <ArrowRight className="h-4 w-4 ml-2" />
                </button>
              ) : (
                <button
                  type="submit"
                  onClick={handleSubmit}
                  disabled={!formData.full_name.trim() || isSaving}
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50"
                >
                  {isSaving ? 'Saving...' : 'Complete Setup'}
                  <Check className="h-4 w-4 ml-2" />
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}