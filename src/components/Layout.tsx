import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuthStore } from '../lib/store';
import { 
  LayoutDashboard,
  Building2,
  MessageSquare,
  Users,
  BookOpen,
  Settings,
  LogOut,
  Menu,
  X,
  Bell,
  Search,
  Shield,
  Lightbulb,
  User,
  UserCircle,
  ChevronDown
} from 'lucide-react';
import { supabase } from '../lib/supabase';

interface NavItem {
  id: string;
  name: string;
  href: string;
  icon: React.ElementType;
  badge?: string;
}

export default function Layout() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, profile, isAdmin, signOut } = useAuthStore();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);
  const [hasCompany, setHasCompany] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (user) {
      checkCompanyAccess();
    }
  }, [user]);

  const checkCompanyAccess = async () => {
    if (!user) return;

    try {
      setIsLoading(true);

      // Check if user owns any companies
      const { data: ownedCompanies, error: ownedError } = await supabase
        .from('companies')
        .select('id')
        .eq('owner_id', user.id);

      if (ownedError) throw ownedError;

      if (ownedCompanies && ownedCompanies.length > 0) {
        setHasCompany(true);
        return;
      }

      // Check if user is a member of any companies
      const { data: memberships, error: memberError } = await supabase
        .from('company_members')
        .select('company_id')
        .eq('user_id', user.id);

      if (memberError) throw memberError;

      setHasCompany(memberships && memberships.length > 0);
    } catch (error) {
      console.error('Error checking company access:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSignOut = async () => {
    await signOut();
    navigate('/login');
  };

  const navigation: NavItem[] = [
    { 
      id: 'dashboard',
      name: 'Dashboard', 
      href: '/dashboard', 
      icon: LayoutDashboard 
    },
    { 
      id: 'company',
      name: 'My Company', 
      href: hasCompany ? '/company/dashboard' : '/company/setup', 
      icon: Building2,
      badge: !hasCompany && !isLoading ? 'Setup' : undefined
    },
    { 
      id: 'messages',
      name: 'Messages', 
      href: '/messages', 
      icon: MessageSquare 
    },
    { 
      id: 'community',
      name: 'Community', 
      href: '/community', 
      icon: Users 
    },
    { 
      id: 'directory',
      name: 'Directory', 
      href: '/directory', 
      icon: BookOpen 
    },
    { 
      id: 'idea-hub',
      name: 'Idea Hub', 
      href: '/idea-hub', 
      icon: Lightbulb 
    },
    { 
      id: 'settings',
      name: 'Settings', 
      href: '/profile', 
      icon: Settings 
    }
  ];

  // Add admin panel for admins
  if (isAdmin) {
    navigation.push({
      id: 'admin',
      name: 'Admin Panel',
      href: '/admin',
      icon: Shield
    });
  }

  const renderNavItem = (item: NavItem) => {
    return (
      <Link
        key={item.id}
        to={item.href}
        className={`${
          location.pathname === item.href
            ? 'bg-indigo-50 text-indigo-600'
            : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
        } group flex items-center px-2 py-2 text-sm font-medium rounded-md`}
      >
        <item.icon
          className={`${
            location.pathname === item.href
              ? 'text-indigo-600'
              : 'text-gray-400 group-hover:text-gray-500'
          } mr-3 h-5 w-5`}
        />
        {item.name}
        {item.badge && (
          <span className="ml-auto inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
            {item.badge}
          </span>
        )}
      </Link>
    );
  };

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Top Navigation */}
      <div className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex">
              <div className="flex-shrink-0 flex items-center">
                <Shield className="h-8 w-8 text-indigo-600" />
              </div>
              <div className="hidden lg:ml-6 lg:flex lg:items-center">
                <div className="max-w-lg w-full lg:max-w-xs">
                  <label htmlFor="search" className="sr-only">Search</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <Search className="h-5 w-5 text-gray-400" />
                    </div>
                    <input
                      id="search"
                      name="search"
                      className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      placeholder="Search resources..."
                      type="search"
                    />
                  </div>
                </div>
              </div>
            </div>
            <div className="flex items-center">
              <button className="p-1 rounded-full text-gray-400 hover:text-gray-500">
                <Bell className="h-6 w-6" />
              </button>
              <div className="ml-4 relative">
                <div>
                  <button
                    onClick={() => setIsProfileMenuOpen(!isProfileMenuOpen)}
                    className="flex items-center max-w-xs bg-white rounded-full focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    <span className="sr-only">Open user menu</span>
                    <div className="flex items-center space-x-3 p-2 hover:bg-gray-50 rounded-lg">
                      {profile?.avatar_url ? (
                        <img
                          className="h-8 w-8 rounded-full"
                          src={profile.avatar_url}
                          alt=""
                        />
                      ) : (
                        <UserCircle className="h-8 w-8 text-gray-400" />
                      )}
                      <div className="hidden md:block text-left">
                        <div className="text-sm font-medium text-gray-700">
                          {profile?.full_name || 'Complete Profile'}
                        </div>
                        <div className="text-xs text-gray-500 capitalize">
                          {profile?.role || 'New User'}
                        </div>
                      </div>
                      <ChevronDown className="h-4 w-4 text-gray-400" />
                    </div>
                  </button>
                </div>
                {isProfileMenuOpen && (
                  <div className="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 py-1">
                    {!profile?.full_name ? (
                      <Link
                        to="/profile-setup"
                        className="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                        onClick={() => setIsProfileMenuOpen(false)}
                      >
                        <User className="h-4 w-4 mr-3" />
                        Complete Profile
                      </Link>
                    ) : (
                      <Link
                        to="/profile"
                        className="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                        onClick={() => setIsProfileMenuOpen(false)}
                      >
                        <User className="h-4 w-4 mr-3" />
                        Your Profile
                      </Link>
                    )}
                    {isAdmin && (
                      <Link
                        to="/admin"
                        className="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                        onClick={() => setIsProfileMenuOpen(false)}
                      >
                        <Shield className="h-4 w-4 mr-3" />
                        Admin Panel
                      </Link>
                    )}
                    <button
                      onClick={() => {
                        setIsProfileMenuOpen(false);
                        handleSignOut();
                      }}
                      className="flex w-full items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                    >
                      <LogOut className="h-4 w-4 mr-3" />
                      Sign Out
                    </button>
                  </div>
                )}
              </div>
              <div className="ml-4 flex items-center lg:hidden">
                <button
                  onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                  className="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100"
                >
                  {isMobileMenuOpen ? (
                    <X className="h-6 w-6" />
                  ) : (
                    <Menu className="h-6 w-6" />
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Mobile menu */}
        {isMobileMenuOpen && (
          <div className="lg:hidden">
            <div className="pt-2 pb-3 space-y-1">
              {navigation.map((item) => (
                <Link
                  key={item.id}
                  to={item.href}
                  className={`${
                    location.pathname === item.href
                      ? 'bg-indigo-50 border-indigo-500 text-indigo-700'
                      : 'border-transparent text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700'
                  } block pl-3 pr-4 py-2 border-l-4 text-base font-medium flex items-center`}
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  <item.icon className="h-5 w-5 mr-2" />
                  {item.name}
                  {item.badge && (
                    <span className="ml-auto inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
                      {item.badge}
                    </span>
                  )}
                </Link>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Left Sidebar and Main Content */}
      <div className="flex">
        {/* Left Sidebar */}
        <div className="hidden lg:flex lg:flex-shrink-0">
          <div className="flex flex-col w-64 border-r border-gray-200 bg-white">
            <div className="flex-1 flex flex-col pt-5 pb-4 overflow-y-auto">
              <nav className="flex-1 px-2 space-y-1">
                {navigation.map(renderNavItem)}
              </nav>
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="flex-1">
          <div className="py-6">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              <Outlet />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}