import React, { Suspense, lazy } from 'react';
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { useAuthStore } from './lib/store';

// Lazy load components
const Login = lazy(() => import('./pages/Login'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Profile = lazy(() => import('./pages/Profile'));
const ProfileSetup = lazy(() => import('./pages/ProfileSetup'));
const Directory = lazy(() => import('./pages/Directory'));
const CofounderBot = lazy(() => import('./pages/idea-hub/CofounderBot'));
const AdminPanel = lazy(() => import('./pages/AdminPanel'));
const CompanySetup = lazy(() => import('./pages/company/CompanySetup'));
const CompanyDashboard = lazy(() => import('./pages/company/CompanyDashboard'));
const CompanySettings = lazy(() => import('./pages/company/CompanySettings'));
const IdeaHub = lazy(() => import('./pages/IdeaHub'));
const Community = lazy(() => import('./pages/Community'));
const Messages = lazy(() => import('./pages/Messages'));
const Layout = lazy(() => import('./components/Layout'));
const GoogleCallback = lazy(() => import('./pages/auth/GoogleCallback'));

// Loading fallback component
const LoadingFallback = () => (
  <div className="min-h-screen flex items-center justify-center">
    <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-indigo-500"></div>
  </div>
);

function App() {
  const { user, profile } = useAuthStore();
  const location = useLocation();

  // If user is not logged in, show login page
  if (!user) {
    return (
      <Suspense fallback={<LoadingFallback />}>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/auth/google/callback" element={<GoogleCallback />} />
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </Suspense>
    );
  }

  // If user is logged in but hasn't completed profile setup and isn't on the setup page,
  // redirect to setup
  if (!profile?.full_name && location.pathname !== '/profile-setup') {
    return <Navigate to="/profile-setup" replace />;
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <Suspense fallback={<LoadingFallback />}>
        <Routes>
          <Route path="/login" element={<Navigate to="/dashboard" replace />} />
          <Route path="/auth/google/callback" element={<GoogleCallback />} />
          <Route path="/profile-setup" element={<ProfileSetup />} />
          
          {/* Protected Routes */}
          <Route element={<PrivateRoute><Layout /></PrivateRoute>}>
            <Route index element={<Navigate to="/dashboard" />} />
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="profile" element={<Profile />} />
            <Route path="directory" element={<Directory />} />
            <Route path="messages" element={<Messages />} />
            <Route path="idea-hub/cofounder-bot" element={<CofounderBot />} />
            <Route path="community" element={<Community />} />
            <Route path="idea-hub/*" element={<IdeaHub />} />
            <Route path="company">
              <Route path="setup" element={<CompanySetup />} />
              <Route path="dashboard" element={<CompanyDashboard />} />
              <Route path="settings" element={<CompanySettings />} />
            </Route>
            <Route path="admin" element={<AdminPanel />} />
          </Route>
        </Routes>
      </Suspense>
    </div>
  );
}

function PrivateRoute({ children }: { children: React.ReactNode }) {
  const { user, profile } = useAuthStore();
  
  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (!profile?.full_name) {
    return <Navigate to="/profile-setup" replace />;
  }

  return <>{children}</>;
}

export default App;