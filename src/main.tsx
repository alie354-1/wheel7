import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter as Router } from 'react-router-dom';
import { supabase } from './lib/supabase';
import { useAuthStore } from './lib/store';
import App from './App.tsx';
import './index.css';

// Initialize auth state
const initAuth = async () => {
  try {
    // Get initial session
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    if (sessionError) throw sessionError;

    const { setUser, fetchProfile } = useAuthStore.getState();

    if (session?.user) {
      setUser(session.user);
      await fetchProfile(session.user.id);
    }

    // Listen for auth changes
    supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
        if (session?.user) {
          setUser(session.user);
          await fetchProfile(session.user.id);
        }
      } else if (event === 'SIGNED_OUT') {
        setUser(null);
      }
    });
  } catch (error) {
    console.error('Error initializing auth:', error);
  }
};

// Initialize auth and render app
initAuth().then(() => {
  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <Router>
        <App />
      </Router>
    </StrictMode>
  );
});