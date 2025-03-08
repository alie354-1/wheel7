import React from 'react';
import { Link, useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuthStore } from '../lib/store';
import * as Tooltip from '@radix-ui/react-tooltip';
import { 
  LayoutDashboard,
  Building2,
  MessageSquare,
  Users,
  BookOpen,
  FileText,
  Wallet,
  Settings,
  LogOut,
  Menu,
  X,
  Bell,
  Search,
  Shield,
  Scale,
  Code2,
  Wrench,
  Lightbulb,
  PiggyBank,
  ChevronDown,
  User,
  UserCircle,
  Construction
} from 'lucide-react';
import { supabase } from '../lib/supabase';

interface NavItem {
  name: string;
  href: string;
  icon: React.ElementType;
  badge?: string;
  isEnabled?: boolean;
  children?: NavItem[];
}

// Custom hook for company access check
const useCompanyAccess = () => {
  const { user } = useAuthStore();
  const [hasCompany, setHasCompany] = React.useState(false);
  const [isLoading, setIsLoading] = React.useState(true);

  React.useEffect(() => {
    const checkCompanyAccess = async () => {
      if (!user) return;

      try {
        setIsLoading(true);

        const [ownedCompanies, memberships] = await Promise.all([
          supabase
            .from('companies')
            .select('id')
            .eq('owner_id', user.id),
          supabase
            .from('company_members')
            .select('company_id')
            .eq('user_id', user.id)
        ]);

        if (ownedCompanies.error) throw ownedCompanies.error;
        if (memberships.error) throw memberships.error;

        setHasCompany(
          (ownedCompanies.data?.length ?? 0) > 0 || 
          (memberships.data?.length ?? 0) > 0
        );
      } catch (error) {
        console.error('Error checking company access:', error);
      } finally {
        setIsLoading(false);
      }
    };

    checkCompanyAccess();
  }, [user]);

  return { hasCompany, isLoading };
};

// Custom hook for navigation items
const useNavigation = (hasCompany: boolean, isLoading: boolean, isAdmin: boolean) => {
  const navigation: NavItem[] = React.useMemo(() => [
    { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard, isEnabled: true },
    { 
      name: 'My Company', 
      href: hasCompany ? '/company/dashboard' : '/company/setup', 
      icon: Building2,
      badge: !hasCompany && !isLoading ? 'Setup' : undefined,
      isEnabled: true
    },
    { name: 'Messages', href: '/messages', icon: MessageSquare, isEnabled: true },
    { name: 'Community', href: '/community', icon: Users, isEnabled: true },
    { name: 'Directory', href: '/directory', icon: BookOpen, isEnabled: true },
    { name: 'Library', href: '#', icon: FileText, isEnabled: false },
    { name: 'Marketplace', href: '#', icon: Wallet, isEnabled: false },
    { name: 'Legal Hub', href: '#', icon: Scale, isEnabled: false },
    { name: 'Dev Hub', href: '#', icon: Code2, isEnabled: false },
    { name: 'Utilities', href: '#', icon: Wrench, isEnabled: false },
    { name: 'Idea Hub', href: '/idea-hub', icon: Lightbulb, isEnabled: true },
    { name: 'Finance Hub', href: '#', icon: PiggyBank, isEnabled: false },
    { name: 'Settings', href: '/profile', icon: Settings, isEnabled: true, children: [
      ...(isAdmin ? [{ name: 'Admin Panel', href: '/admin', icon: Shield, isEnabled: true }] : [])
    ]},
  ], [hasCompany, isLoading, isAdmin]);

  return navigation;
};

// NavItem component
const NavItemComponent: React.FC<{ item: NavItem; isMobile?: boolean }> = ({ item, isMobile = false }) => {
  const location = useLocation();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = React.useState(false);

  if (!item.isEnabled) {
    return (
      <Tooltip.Provider>
        <Tooltip.Root>
          <Tooltip.Trigger asChild>
            <div className={`
              ${isMobile 
                ? 'block pl-3 pr-4 py-2 border-l-4 border-transparent text-base font-medium text-gray-400 flex items-center cursor-not-allowed group'
                : 'flex items-center px-2 py-2 text-sm font-medium text-gray-400 cursor-not-allowed rounded-md group'
              }
            `}>
              <item.icon className={`${isMobile ? 'h-5 w-5 mr-2' : 'h-5 w-5 mr-3'}`} />
              {item.name}
              <Construction className="h-4 w-4 ml-2 opacity-0 group-hover:opacity-100 transition-opacity" />
            </div>
          </Tooltip.Trigger>
          <Tooltip.Portal>
            <Tooltip.Content
              className="bg-gray-900 text-white px-3 py-1.5 rounded text-sm"
              sideOffset={5}
            >
              Coming Soon
              <Tooltip.Arrow className="fill-gray-900" />
            </Tooltip.Content>
          </Tooltip.Portal>
        </Tooltip.Root>
      </Tooltip.Provider>
    );
  }

  const linkClasses = isMobile
    ? `${
        location.pathname === item.href
          ? 'bg-indigo-50 border-indigo-500 text-indigo-700'
          : 'border-transparent text-gray-500 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-700'
      } block pl-3 pr-4 py-2 border-l-4 text-base font-medium flex items-center`
    : `${
        location.pathname === item.href
          ? 'bg-indigo-50 text-indigo-600'
          : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
      } group flex items-center px-2 py-2 text-sm font-medium rounded-md`;

  return (
    <Link
      to={item.href}
      className={linkClasses}
      onClick={() => isMobile && setIsMobileMenuOpen(false)}
    >
      <item.icon
        className={`${
          location.pathname === item.href
            ? 'text-indigo-600'
            : 'text-gray-400 group-hover:text-gray-500'
        } ${isMobile ? 'mr-2' : 'mr-3'} h-5 w-5`}
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

export default function Layout() {
  const navigate = useNavigate();
  const { user, profile, isAdmin, signOut } = useAuthStore();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = React.useState(false);
  const [isProfileMenuOpen, setIsProfileMenuOpen] = React.useState(false);
  const { hasCompany, isLoading } = useCompanyAccess();
  const navigation = useNavigation(hasCompany, isLoading, isAdmin);

  const handleSignOut = async () => {
    await signOut();
    navigate('/login');
  };

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Top Navigation */}
      <div className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            {/* Left side */}
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

            {/* Right side */}
            <div className="flex items-center">
              <button 
                className="p-1 rounded-full text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                aria-label="Notifications"
              >
                <Bell className="h-6 w-6" />
              </button>

              {/* Profile dropdown */}
              <div className="ml-4 relative">
                <button
                  className="flex items-center space-x-2 text-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 rounded-full"
                  onClick={() => setIsProfileMenuOpen(!isProfileMenuOpen)}
                >
                  <UserCircle className="h-8 w-8 text-gray-400" />
                  <ChevronDown className="h-4 w-4 text-gray-400" />
                </button>

                {isProfileMenuOpen && (
                  <div className="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5">
                    <div className="py-1">
                      <Link
                        to="/profile"
                        className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                      >
                        Your Profile
                      </Link>
                      <button
                        onClick={handleSignOut}
                        className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                      >
                        Sign Out
                      </button>
                    </div>
                  </div>
                )}
              </div>

              {/* Mobile menu button */}
              <div className="flex items-center lg:hidden">
                <button
                  className="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500"
                  onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                >
                  <span className="sr-only">Open main menu</span>
                  {isMobileMenuOpen ? (
                    <X className="block h-6 w-6" />
                  ) : (
                    <Menu className="block h-6 w-6" />
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Mobile menu */}
      {isMobileMenuOpen && (
        <div className="lg:hidden">
          <div className="pt-2 pb-3 space-y-1">
            {navigation.map((item) => (
              <NavItemComponent key={item.name} item={item} isMobile />
            ))}
          </div>
        </div>
      )}

      {/* Desktop sidebar */}
      <div className="hidden lg:flex lg:flex-col lg:w-64 lg:fixed lg:inset-y-0 lg:border-r lg:border-gray-200 lg:pt-5 lg:pb-4 lg:bg-gray-100">
        <div className="flex-1 flex flex-col overflow-y-auto">
          <nav className="mt-5 flex-1 px-2 space-y-1">
            {navigation.map((item) => (
              <NavItemComponent key={item.name} item={item} />
            ))}
          </nav>
        </div>
      </div>

      {/* Main content */}
      <div className="lg:pl-64">
        <main className="flex-1">
          <div className="py-6">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              <Outlet />
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}