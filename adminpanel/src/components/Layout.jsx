// components/Layout.jsx

import { useState } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import {
  LayoutDashboard,
  Users,
  FileText,
  Award,
  FolderOpen,
  BarChart3,
  Menu,
  X,
  LogOut,
  User,
  Bell,
} from 'lucide-react';
import { useAuthStore } from '../lib/store';

const Layout = () => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const navItems = [
    { path: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { path: '/users', label: 'Users', icon: Users },
    { path: '/posts', label: 'Posts', icon: FileText },
    { path: '/claims', label: 'Claims', icon: Award },
    { path: '/categories', label: 'Categories', icon: FolderOpen },
    { path: '/reports', label: 'Reports', icon: BarChart3 },
  ];

  return (
    <div className="min-h-screen bg-[#f6f7fb] flex">
      {/* MOBILE SIDEBAR OVERLAY */}
      <AnimatePresence>
        {sidebarOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 0.5 }}
            exit={{ opacity: 0 }}
            onClick={() => setSidebarOpen(false)}
            className="fixed inset-0 bg-black z-40 lg:hidden"
          />
        )}
      </AnimatePresence>

      {/* SIDEBAR */}
      <aside
        className={`fixed top-0 left-0 h-full w-64 bg-white shadow-xl border-r border-gray-100 z-50 
        transition-transform duration-300 
        ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'} 
        lg:translate-x-0`}
      >
        {/* LOGO */}
        <div className="h-16 px-6 flex items-center justify-between border-b border-gray-100">
          <motion.h1
            initial={{ opacity: 0, x: -10 }}
            animate={{ opacity: 1, x: 0 }}
            className="text-xl font-bold text-gray-900 tracking-tight"
          >
            Admin Panel
          </motion.h1>

          <button
            onClick={() => setSidebarOpen(false)}
            className="lg:hidden p-2 hover:bg-gray-100 rounded-lg transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* NAVIGATION */}
        <nav className="p-4 space-y-1 overflow-y-auto" style={{ maxHeight: 'calc(100vh - 180px)' }}>
          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              onClick={() => setSidebarOpen(false)}
              className={({ isActive }) =>
                `
                group flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200
                ${
                  isActive
                    ? 'bg-blue-600 text-white shadow-md'
                    : 'text-gray-700 hover:bg-gray-100 hover:text-gray-900'
                }
              `
              }
            >
              <item.icon
                className={`w-5 h-5 transition ${
                  item.isActive ? 'text-white' : 'group-hover:text-gray-900'
                }`}
              />
              <span className="font-medium">{item.label}</span>
            </NavLink>
          ))}
        </nav>

        {/* USER INFO */}
        <div className="absolute bottom-0 left-0 right-0 p-4 border-t border-gray-100 bg-white">
          <div className="flex items-center gap-3 px-4 py-3 bg-gray-50/70 rounded-xl shadow-sm">
            <div className="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center text-white font-semibold">
              {user?.name?.[0]?.toUpperCase() || 'A'}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-gray-900 truncate">
                {user?.name || 'Admin User'}
              </p>
              <p className="text-xs text-gray-500 truncate">
                {user?.email || 'admin@example.com'}
              </p>
            </div>
          </div>
        </div>
      </aside>

      {/* MAIN CONTENT */}
      <div className="flex-1 lg:ml-64 min-h-screen">
        {/* NAVBAR */}
        <header className="h-16 bg-white border-b border-gray-200 sticky top-0 z-30 shadow-sm">
          <div className="h-full px-4 lg:px-8 flex items-center justify-between">
            <div className="flex items-center gap-4">
              <button
                onClick={() => setSidebarOpen(true)}
                className="lg:hidden p-2 hover:bg-gray-100 rounded-lg transition"
              >
                <Menu className="w-6 h-6 text-gray-800" />
              </button>

              <h2 className="text-lg font-semibold text-gray-900 hidden lg:block">
                Lost & Found Admin
              </h2>
            </div>

            {/* RIGHT SIDE ACTIONS */}
            <div className="flex items-center gap-4">
              {/* NOTIFICATIONS */}
              <button className="relative p-2 hover:bg-gray-100 rounded-lg transition">
                <Bell className="w-5 h-5 text-gray-600" />
                <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
              </button>

              {/* PROFILE */}
              <div className="relative">
                <button
                  onClick={() => setShowProfileMenu(!showProfileMenu)}
                  className="flex items-center gap-3 p-2 hover:bg-gray-100 rounded-lg transition"
                >
                  <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center text-white font-semibold text-sm">
                    {user?.name?.[0]?.toUpperCase() || 'A'}
                  </div>
                  <span className="hidden md:block text-sm font-medium text-gray-700">
                    {user?.name || 'Admin'}
                  </span>
                </button>

                {/* DROPDOWN */}
                <AnimatePresence>
                  {showProfileMenu && (
                    <>
                      <div
                        className="fixed inset-0 z-40"
                        onClick={() => setShowProfileMenu(false)}
                      />

                      <motion.div
                        initial={{ opacity: 0, y: -8 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: -8 }}
                        className="absolute right-0 mt-2 w-60 bg-white border border-gray-200 rounded-lg shadow-xl overflow-hidden z-50"
                      >
                        <div className="p-4 border-b border-gray-100">
                          <p className="text-sm font-semibold text-gray-900">
                            {user?.name || 'Admin User'}
                          </p>
                          <p className="text-xs text-gray-500">{user?.email || 'admin@example.com'}</p>
                        </div>

                        <div className="p-2">
                          <button
                            className="w-full flex items-center gap-3 px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-lg transition"
                          >
                            <User className="w-4 h-4" />
                            Profile Settings
                          </button>

                          <button
                            onClick={handleLogout}
                            className="w-full flex items-center gap-3 px-3 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg transition"
                          >
                            <LogOut className="w-4 h-4" />
                            Logout
                          </button>
                        </div>
                      </motion.div>
                    </>
                  )}
                </AnimatePresence>
              </div>
            </div>
          </div>
        </header>

        {/* CONTENT */}
        <main className="p-4 lg:p-8 min-h-[calc(100vh-64px)] bg-[#f6f7fb]">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default Layout;
