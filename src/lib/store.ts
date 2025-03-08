import { create } from 'zustand';
import { User } from '@supabase/supabase-js';
import { supabase } from './supabase';

interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  avatar_url: string | null;
  role: 'user' | 'admin' | 'superadmin';
  is_public: boolean;
  allows_messages: boolean;
  settings?: Record<string, any>;
  setup_progress?: {
    current_step: string;
    completed_steps: string[];
    form_data: Record<string, any>;
  };
}

export interface FeatureFlags {
  [key: string]: {
    enabled: boolean;
    visible: boolean;
  };
}

interface AuthStore {
  user: User | null;
  profile: UserProfile | null;
  isAdmin: boolean;
  isSuperAdmin: boolean;
  isLoading: boolean;
  featureFlags: FeatureFlags;
  setUser: (user: User | null) => void;
  setProfile: (profile: UserProfile | null) => void;
  setFeatureFlags: (flags: Partial<FeatureFlags>) => void;
  updateSetupProgress: (progress: {
    current_step: string;
    completed_steps: string[];
    form_data: Record<string, any>;
  }) => Promise<void>;
  fetchProfile: (userId: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const defaultFeatureFlags: FeatureFlags = {
  ideaHub: { enabled: true, visible: true },
  community: { enabled: true, visible: true },
  messages: { enabled: true, visible: true },
  directory: { enabled: true, visible: true },
  library: { enabled: false, visible: false },
  marketplace: { enabled: false, visible: false },
  legalHub: { enabled: false, visible: false },
  devHub: { enabled: false, visible: false },
  utilities: { enabled: false, visible: false },
  financeHub: { enabled: false, visible: false },
  adminPanel: { enabled: true, visible: true },
  aiCofounder: { enabled: true, visible: true },
  marketResearch: { enabled: true, visible: true },
  pitchDeck: { enabled: true, visible: true },
  documentStore: { enabled: true, visible: true },
  teamManagement: { enabled: true, visible: true }
};

export const useAuthStore = create<AuthStore>((set, get) => ({
  user: null,
  profile: null,
  isAdmin: false,
  isSuperAdmin: false,
  isLoading: true,
  featureFlags: defaultFeatureFlags,

  setUser: (user) => set({ user }),
  
  setProfile: (profile) => set({
    profile,
    isAdmin: profile?.role === 'admin' || profile?.role === 'superadmin',
    isSuperAdmin: profile?.role === 'superadmin'
  }),

  setFeatureFlags: (flags) => set(state => ({
    featureFlags: {
      ...state.featureFlags,
      ...flags
    }
  })),

  updateSetupProgress: async (progress) => {
    const { user } = get();
    if (!user) return;

    try {
      const { error } = await supabase
        .from('profiles')
        .update({
          setup_progress: progress,
          updated_at: new Date().toISOString()
        })
        .eq('id', user.id);

      if (error) throw error;

      set(state => ({
        profile: state.profile ? {
          ...state.profile,
          setup_progress: progress
        } : null
      }));
    } catch (error) {
      console.error('Error updating setup progress:', error);
      throw error;
    }
  },

  fetchProfile: async (userId) => {
    try {
      set({ isLoading: true });

      const { data: profile, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (error && error.code !== 'PGRST116') {
        throw error;
      }

      if (profile) {
        set({
          profile,
          isAdmin: profile.role === 'admin' || profile.role === 'superadmin',
          isSuperAdmin: profile.role === 'superadmin',
          featureFlags: {
            ...defaultFeatureFlags,
            ...(profile.settings?.feature_flags || {})
          }
        });
      } else {
        // Create new profile with default settings
        const { data: newProfile, error: createError } = await supabase
          .from('profiles')
          .insert([{
            id: userId,
            email: (await supabase.auth.getUser()).data.user?.email,
            role: 'user',
            is_public: true,
            allows_messages: true,
            setup_progress: {
              current_step: 'basic',
              completed_steps: [],
              form_data: {}
            },
            settings: {
              notifications: {
                email: true,
                push: true
              },
              privacy: {
                showProfile: true,
                allowMessages: true
              },
              feature_flags: defaultFeatureFlags
            }
          }])
          .select()
          .single();

        if (createError) throw createError;

        if (newProfile) {
          set({
            profile: newProfile,
            isAdmin: false,
            isSuperAdmin: false,
            featureFlags: defaultFeatureFlags
          });
        }
      }
    } catch (error) {
      console.error('Error in fetchProfile:', error);
      throw error;
    } finally {
      set({ isLoading: false });
    }
  },

  signOut: async () => {
    try {
      await supabase.auth.signOut();
      // Clear all auth state
      set({ 
        user: null, 
        profile: null, 
        isAdmin: false, 
        isSuperAdmin: false,
        isLoading: false,
        featureFlags: defaultFeatureFlags
      });
      // Clear local storage
      window.localStorage.removeItem('supabase.auth.token');
    } catch (error) {
      console.error('Error signing out:', error);
      throw error;
    }
  }
}));
