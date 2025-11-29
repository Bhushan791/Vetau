// pages/Users.jsx - User Management Page (PERFECT VERSION)

import { useState, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { Eye, Ban, Trash2, RotateCcw, X, AlertCircle, CheckCircle, Shield, Mail, MapPin, Calendar } from 'lucide-react';
import Table from '../components/Table';
import { usersAPI } from '../lib/api';

const Users = () => {
  const [selectedUser, setSelectedUser] = useState(null);
  const [showModal, setShowModal] = useState(false);
  const [showViewModal, setShowViewModal] = useState(false);
  const [banReason, setBanReason] = useState('');
  const [activeFilters, setActiveFilters] = useState({});
  const [notification, setNotification] = useState(null);
  const notificationTimeout = useRef(null);

  const queryClient = useQueryClient();

  // Fetch users with filters
  const { data: usersData, isLoading } = useQuery({
    queryKey: ['users', activeFilters],
    queryFn: () => usersAPI.getAll(activeFilters),
  });

  // Unified notification function
  const showNotification = (message, type) => {
    clearTimeout(notificationTimeout.current);
    setNotification({ message, type });
    notificationTimeout.current = setTimeout(() => setNotification(null), 3000);
  };

  // Ban user mutation
  const banMutation = useMutation({
    mutationFn: ({ userId, reason }) => usersAPI.ban(userId, reason),
    onSuccess: () => {
      queryClient.invalidateQueries(['users']);
      showNotification('User banned successfully', 'success');
      setSelectedUser(null);
      setShowModal(false);
      setBanReason('');
    },
    onError: (error) => {
      showNotification(error.response?.data?.message || 'Failed to ban user', 'error');
    },
  });

  // Unban user mutation
  const unbanMutation = useMutation({
    mutationFn: (userId) => usersAPI.unban(userId),
    onSuccess: () => {
      queryClient.invalidateQueries(['users']);
      showNotification('User unbanned successfully', 'success');
    },
    onError: (error) => {
      showNotification(error.response?.data?.message || 'Failed to unban user', 'error');
    },
  });

  // Soft delete user mutation
  const deleteMutation = useMutation({
    mutationFn: (userId) => usersAPI.softDelete(userId),
    onSuccess: () => {
      queryClient.invalidateQueries(['users']);
      showNotification('User deleted successfully', 'success');
    },
    onError: (error) => {
      showNotification(error.response?.data?.message || 'Failed to delete user', 'error');
    },
  });

  // Restore user mutation
  const restoreMutation = useMutation({
    mutationFn: (userId) => usersAPI.restore(userId),
    onSuccess: () => {
      queryClient.invalidateQueries(['users']);
      showNotification('User restored successfully', 'success');
    },
    onError: (error) => {
      showNotification(error.response?.data?.message || 'Failed to restore user', 'error');
    },
  });

  const handleBanUser = (user) => {
    setSelectedUser(user);
    setShowModal(true);
  };

  const handleViewUser = (user) => {
    setSelectedUser(user);
    setShowViewModal(true);
  };

  const confirmBan = () => {
    if (!banReason.trim()) {
      showNotification('Please provide a reason for banning', 'error');
      return;
    }
    banMutation.mutate({ userId: selectedUser.userId, reason: banReason });
  };

  const handleExport = async () => {
    try {
      const csvData = await usersAPI.export(activeFilters);
      const blob = new Blob([csvData], { type: 'text/csv' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `users-${new Date().toISOString().split('T')[0]}.csv`;
      a.click();
      showNotification('Users exported successfully', 'success');
    } catch (error) {
      showNotification('Failed to export users', 'error');
    }
  };

  const columns = [
    {
      key: 'fullName',
      label: 'User',
      render: (value, row) => (
        <div className="flex items-center gap-3">
          <motion.img
            whileHover={{ scale: 1.1 }}
            src={row.profileImage}
            alt={value}
            className="w-10 h-10 rounded-full border-2 border-blue-200 shadow-sm object-cover"
            onError={(e) => {
              e.target.onerror = null;
              e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(value)}&background=3b82f6&color=fff`;
            }}
          />
          <div>
            <p className="font-semibold text-gray-900">{value}</p>
            <p className="text-xs text-gray-500">@{row.username}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'email',
      label: 'Email',
      render: (value) => (
        <span className="text-sm text-gray-600">{value}</span>
      ),
    },
    {
      key: 'role',
      label: 'Role',
      render: (value) => (
        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
          value === 'admin' 
            ? 'bg-gradient-to-r from-purple-100 to-indigo-100 text-purple-700 border border-purple-200' 
            : 'bg-gradient-to-r from-blue-100 to-cyan-100 text-blue-700 border border-blue-200'
        }`}>
          {value}
        </span>
      ),
    },
    {
      key: 'status',
      label: 'Status',
      render: (_, row) => {
        if (row.isDeleted) {
          return (
            <span className="px-3 py-1 rounded-full text-xs font-semibold bg-gradient-to-r from-gray-100 to-gray-200 text-gray-700 border border-gray-300">
              Deleted
            </span>
          );
        }
        if (row.status === 'banned') {
          return (
            <span className="px-3 py-1 rounded-full text-xs font-semibold bg-gradient-to-r from-red-100 to-rose-100 text-red-700 border border-red-200">
              Banned
            </span>
          );
        }
        return (
          <span className="px-3 py-1 rounded-full text-xs font-semibold bg-gradient-to-r from-green-100 to-emerald-100 text-green-700 border border-green-200">
            Active
          </span>
        );
      },
    },
    {
      key: 'createdAt',
      label: 'Joined',
      render: (value) => (
        <span className="text-sm text-gray-600">
          {new Date(value).toLocaleDateString('en-US', { 
            month: 'short', 
            day: 'numeric', 
            year: 'numeric' 
          })}
        </span>
      ),
    },
  ];

  const filters = [
    {
      key: 'role',
      label: 'Role',
      options: [
        { value: 'user', label: 'User' },
        { value: 'admin', label: 'Admin' },
      ],
    },
    {
      key: 'status',
      label: 'Status',
      options: [
        { value: 'active', label: 'Active' },
        { value: 'banned', label: 'Banned' },
        { value: 'deleted', label: 'Deleted' },
      ],
    },
  ];

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="space-y-6"
    >
      {/* Notification */}
      <AnimatePresence>
        {notification && (
          <motion.div
            initial={{ opacity: 0, y: -50, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -50, scale: 0.9 }}
            className={`fixed top-4 right-4 z-50 p-4 rounded-xl shadow-2xl flex items-center gap-3 backdrop-blur-sm ${
              notification.type === 'success' 
                ? 'bg-gradient-to-r from-green-50 to-emerald-50 border-2 border-green-200' 
                : 'bg-gradient-to-r from-red-50 to-rose-50 border-2 border-red-200'
            }`}
          >
            {notification.type === 'success' ? (
              <CheckCircle className="w-6 h-6 text-green-600" />
            ) : (
              <AlertCircle className="w-6 h-6 text-red-600" />
            )}
            <p className={`text-sm font-semibold ${notification.type === 'success' ? 'text-green-800' : 'text-red-800'}`}>
              {notification.message}
            </p>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Page Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
          Users Management
        </h1>
        <p className="text-gray-600 mt-1">Manage all registered users and their permissions</p>
      </motion.div>

      {/* Users Table */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
      >
        <Table
          columns={columns}
          data={usersData?.users || []}
          loading={isLoading}
          searchable
          filterable
          filters={filters}
          activeFilters={activeFilters}
          onFilterChange={(key, value) => setActiveFilters({ ...activeFilters, [key]: value })}
          onExport={handleExport}
          actions={(row) => {
            if (!row) return null;
            const userId = row.userId;
            
            if (row.isDeleted) {
              return (
                <motion.button
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => restoreMutation.mutate(userId)}
                  className="p-2 hover:bg-blue-50 rounded-lg transition-colors"
                  title="Restore User"
                >
                  <RotateCcw className="w-4 h-4 text-blue-600" />
                </motion.button>
              );
            }

            return (
              <>
                <motion.button
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => handleViewUser(row)}
                  className="p-2 hover:bg-blue-50 rounded-lg transition-colors"
                  title="View Details"
                >
                  <Eye className="w-4 h-4 text-blue-600" />
                </motion.button>

                {row.status !== 'banned' && (
                  <motion.button
                    whileHover={{ scale: 1.1 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={() => handleBanUser(row)}
                    className="p-2 hover:bg-red-50 rounded-lg transition-colors"
                    title="Ban User"
                  >
                    <Ban className="w-4 h-4 text-red-600" />
                  </motion.button>
                )}

                {row.status === 'banned' && (
                  <motion.button
                    whileHover={{ scale: 1.1 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={() => unbanMutation.mutate(userId)}
                    className="p-2 hover:bg-green-50 rounded-lg transition-colors"
                    title="Unban User"
                  >
                    <RotateCcw className="w-4 h-4 text-green-600" />
                  </motion.button>
                )}

                <motion.button
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => {
                    if (window.confirm('Are you sure you want to delete this user?')) 
                      deleteMutation.mutate(userId);
                  }}
                  className="p-2 hover:bg-red-50 rounded-lg transition-colors"
                  title="Delete User"
                >
                  <Trash2 className="w-4 h-4 text-red-600" />
                </motion.button>
              </>
            );
          }}
        />
      </motion.div>

      {/* View User Modal */}
      <AnimatePresence>
        {showViewModal && selectedUser && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowViewModal(false)}
              className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              onClick={(e) => e.stopPropagation()}
              className="relative bg-white rounded-2xl shadow-2xl max-w-2xl w-full overflow-hidden"
            >
              {/* Header with gradient */}
              <div className="bg-gradient-to-r from-blue-500 to-indigo-600 p-6 text-white">
                <button
                  onClick={() => setShowViewModal(false)}
                  className="absolute top-4 right-4 p-2 hover:bg-white/20 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
                <div className="flex items-center gap-4">
                  <img
                    src={selectedUser.profileImage}
                    alt={selectedUser.fullName}
                    className="w-20 h-20 rounded-full border-4 border-white shadow-lg object-cover"
                    onError={(e) => {
                      e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(selectedUser.fullName)}&background=fff&color=3b82f6&size=128`;
                    }}
                  />
                  <div>
                    <h3 className="text-2xl font-bold">{selectedUser.fullName}</h3>
                    <p className="text-blue-100">@{selectedUser.username}</p>
                  </div>
                </div>
              </div>

              {/* Content */}
              <div className="p-6 space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="p-4 bg-blue-50 rounded-lg border border-blue-100">
                    <div className="flex items-center gap-2 text-blue-600 mb-2">
                      <Mail className="w-4 h-4" />
                      <span className="text-xs font-semibold">Email</span>
                    </div>
                    <p className="text-sm text-gray-900 font-medium">{selectedUser.email}</p>
                  </div>

                  <div className="p-4 bg-purple-50 rounded-lg border border-purple-100">
                    <div className="flex items-center gap-2 text-purple-600 mb-2">
                      <Shield className="w-4 h-4" />
                      <span className="text-xs font-semibold">Role</span>
                    </div>
                    <p className="text-sm text-gray-900 font-medium capitalize">{selectedUser.role}</p>
                  </div>

                  {selectedUser.address && (
                    <div className="p-4 bg-green-50 rounded-lg border border-green-100">
                      <div className="flex items-center gap-2 text-green-600 mb-2">
                        <MapPin className="w-4 h-4" />
                        <span className="text-xs font-semibold">Address</span>
                      </div>
                      <p className="text-sm text-gray-900 font-medium">{selectedUser.address}</p>
                    </div>
                  )}

                  <div className="p-4 bg-orange-50 rounded-lg border border-orange-100">
                    <div className="flex items-center gap-2 text-orange-600 mb-2">
                      <Calendar className="w-4 h-4" />
                      <span className="text-xs font-semibold">Joined</span>
                    </div>
                    <p className="text-sm text-gray-900 font-medium">
                      {new Date(selectedUser.createdAt).toLocaleDateString('en-US', {
                        month: 'long',
                        day: 'numeric',
                        year: 'numeric'
                      })}
                    </p>
                  </div>
                </div>

                {/* Status Badge */}
                <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                  <span className="text-sm font-medium text-gray-700">Account Status</span>
                  {selectedUser.status === 'banned' ? (
                    <span className="px-4 py-2 rounded-full text-sm font-bold bg-gradient-to-r from-red-500 to-rose-500 text-white">
                      Banned
                    </span>
                  ) : (
                    <span className="px-4 py-2 rounded-full text-sm font-bold bg-gradient-to-r from-green-500 to-emerald-500 text-white">
                      Active
                    </span>
                  )}
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Ban User Modal */}
      <AnimatePresence>
        {showModal && selectedUser && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowModal(false)}
              className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              onClick={(e) => e.stopPropagation()}
              className="relative bg-white rounded-2xl shadow-2xl max-w-md w-full p-6"
            >
              <button
                onClick={() => setShowModal(false)}
                className="absolute top-4 right-4 p-2 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <X className="w-5 h-5" />
              </button>

              <div className="flex items-center gap-3 mb-6">
                <div className="p-3 bg-red-100 rounded-full">
                  <Ban className="w-6 h-6 text-red-600" />
                </div>
                <h3 className="text-xl font-bold text-gray-900">Ban User</h3>
              </div>

              <div className="mb-6">
                <p className="text-sm text-gray-600 mb-4">
                  You are about to ban <strong className="text-gray-900">{selectedUser.fullName}</strong>. 
                  Please provide a reason:
                </p>
                <textarea
                  value={banReason}
                  onChange={(e) => setBanReason(e.target.value)}
                  placeholder="Reason for banning..."
                  rows={4}
                  className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent transition-all"
                />
              </div>

              <div className="flex gap-3">
                <button
                  onClick={() => setShowModal(false)}
                  className="flex-1 px-4 py-3 border-2 border-gray-200 rounded-xl hover:bg-gray-50 transition-colors font-medium"
                >
                  Cancel
                </button>
                <button
                  onClick={confirmBan}
                  disabled={banMutation.isPending}
                  className="flex-1 px-4 py-3 bg-gradient-to-r from-red-500 to-rose-600 text-white rounded-xl hover:from-red-600 hover:to-rose-700 transition-all font-medium disabled:opacity-50 shadow-lg"
                >
                  {banMutation.isPending ? 'Banning...' : 'Ban User'}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </motion.div>
  );
};

export default Users;