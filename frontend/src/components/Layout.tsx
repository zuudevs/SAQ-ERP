import { Outlet, Link, useNavigate } from 'react-router-dom';
import { Menu, Users, LogOut, Home, LayoutDashboard } from 'lucide-react';
import { useState } from 'react';

export default function Layout() {
  const navigate = useNavigate();
  const [showUserMenu, setShowUserMenu] = useState(false);
  const userName = localStorage.getItem('user_name') || 'User';
  const userRole = localStorage.getItem('role') || 'ANGGOTA';

  const handleLogout = () => {
    localStorage.clear();
    navigate('/login');
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Navigation */}
      <nav className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex">
              <div className="flex-shrink-0 flex items-center">
                <h1 className="text-xl font-bold text-blue-600">
                  ERP Lab SAQ
                </h1>
              </div>
              <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
                <Link
                  to="/"
                  className="inline-flex items-center px-1 pt-1 text-sm font-medium text-gray-900 hover:text-blue-600 border-b-2 border-transparent hover:border-blue-500"
                >
                  <Home className="mr-2 h-4 w-4" />
                  Dashboard
                </Link>
                <Link
                  to="/members"
                  className="inline-flex items-center px-1 pt-1 text-sm font-medium text-gray-900 hover:text-blue-600 border-b-2 border-transparent hover:border-blue-500"
                >
                  <Users className="mr-2 h-4 w-4" />
                  Anggota
                </Link>
              </div>
            </div>
            
            {/* User Menu */}
            <div className="flex items-center">
              <div className="relative ml-3">
                <button
                  onClick={() => setShowUserMenu(!showUserMenu)}
                  className="flex items-center gap-2 p-2 rounded-md text-gray-700 hover:text-gray-900 hover:bg-gray-100"
                >
                  <div className="h-8 w-8 rounded-full bg-blue-600 flex items-center justify-center text-white font-semibold">
                    {userName.charAt(0).toUpperCase()}
                  </div>
                  <div className="hidden md:block text-left">
                    <p className="text-sm font-medium">{userName}</p>
                    <p className="text-xs text-gray-500">{userRole}</p>
                  </div>
                  <Menu className="h-5 w-5" />
                </button>

                {/* Dropdown Menu */}
                {showUserMenu && (
                  <div className="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 z-50">
                    <div className="py-1">
                      <button
                        onClick={handleLogout}
                        className="w-full flex items-center px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                      >
                        <LogOut className="mr-3 h-4 w-4" />
                        Logout
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <Outlet />
      </main>
    </div>
  );
}