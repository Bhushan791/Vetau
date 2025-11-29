// pages/Posts.jsx - Post Management Page (PERFECT VERSION - Rs Updated)

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { Eye, Trash2, RotateCcw, X, AlertCircle, CheckCircle, MapPin, Image as ImageIcon, Tag, MessageCircle } from 'lucide-react';
import Table from '../components/Table';
import { postsAPI } from '../lib/api';

const Posts = () => {
  const [selectedPost, setSelectedPost] = useState(null);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [activeFilters, setActiveFilters] = useState({});
  const [notification, setNotification] = useState(null);

  const queryClient = useQueryClient();

  // Fetch posts with filters
  const { data: postsData, isLoading } = useQuery({
    queryKey: ['posts', activeFilters],
    queryFn: () => postsAPI.getAll(activeFilters),
  });

  // Delete post mutation
  const deleteMutation = useMutation({
    mutationFn: (postId) => postsAPI.softDelete(postId),
    onSuccess: () => {
      queryClient.invalidateQueries(['posts']);
      showNotification('Post deleted successfully', 'success');
    },
    onError: (error) => {
      showNotification(error.response?.data?.message || 'Failed to delete post', 'error');
    },
  });

  // Restore post mutation
  const restoreMutation = useMutation({
    mutationFn: (postId) => postsAPI.restore(postId),
    onSuccess: () => {
      queryClient.invalidateQueries(['posts']);
      showNotification('Post restored successfully', 'success');
    },
    onError: (error) => {
      showNotification(error.response?.data?.message || 'Failed to restore post', 'error');
    },
  });

  const showNotification = (message, type) => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 3000);
  };

  const handleViewPost = async (post) => {
    try {
      const response = await postsAPI.getById(post.postId);
      setSelectedPost(response.post); // Extract the post object
      setShowDetailModal(true);
    } catch (error) {
      showNotification('Failed to load post details', 'error');
    }
  };

  const handleExport = async () => {
    try {
      const csvData = await postsAPI.export(activeFilters);
      const blob = new Blob([csvData], { type: 'text/csv' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `posts-${new Date().toISOString().split('T')[0]}.csv`;
      a.click();
      showNotification('Posts exported successfully', 'success');
    } catch (error) {
      showNotification('Failed to export posts', 'error');
    }
  };

  const columns = [
    {
      key: 'itemName',
      label: 'Item',
      render: (value, row) => (
        <div className="flex items-center gap-3">
          {row.images && row.images.length > 0 ? (
            <img
              src={row.images[0]}
              alt={value}
              className="w-12 h-12 rounded-lg object-cover border-2 border-blue-200"
            />
          ) : (
            <div className="w-12 h-12 bg-gradient-to-br from-gray-100 to-gray-200 rounded-lg flex items-center justify-center border-2 border-gray-300">
              <ImageIcon className="w-6 h-6 text-gray-400" />
            </div>
          )}
          <div>
            <p className="font-semibold text-gray-900 line-clamp-1">{value}</p>
            <div className="flex items-center gap-2 mt-1">
              <img
                src={row.userId?.profileImage}
                alt={row.userId?.fullName}
                className="w-4 h-4 rounded-full border border-blue-200"
                onError={(e) => {
                  e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(row.userId?.fullName || 'User')}&background=3b82f6&color=fff&size=32`;
                }}
              />
              <p className="text-xs text-gray-500">{row.userId?.fullName || 'Unknown'}</p>
            </div>
          </div>
        </div>
      ),
    },
    {
      key: 'type',
      label: 'Type',
      render: (value) => (
        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
          value === 'found' 
            ? 'bg-gradient-to-r from-green-100 to-emerald-100 text-green-700 border border-green-200' 
            : 'bg-gradient-to-r from-blue-100 to-cyan-100 text-blue-700 border border-blue-200'
        }`}>
          {value}
        </span>
      ),
    },
    {
      key: 'category',
      label: 'Category',
      render: (value) => (
        <span className="text-sm font-medium text-gray-700 capitalize">{value || 'N/A'}</span>
      ),
    },
    {
      key: 'rewardAmount',
      label: 'Reward',
      render: (value) => (
        value ? (
          <span className="font-bold text-green-600 flex items-center gap-1">
            <span className="font-bold text-lg">Rs</span> {/* CHANGED: DollarSign -> Rs */}
            {value.toLocaleString()}
          </span>
        ) : (
          <span className="text-gray-400 text-sm">—</span>
        )
      ),
    },
    {
      key: 'status',
      label: 'Status',
      render: (value, row) => {
        if (row.isDeleted) {
          return (
            <span className="px-3 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-700 border border-gray-300">
              Deleted
            </span>
          );
        }
        const statusConfig = {
          active: { bg: 'from-green-100 to-emerald-100', text: 'text-green-700', border: 'border-green-200' },
          claimed: { bg: 'from-purple-100 to-indigo-100', text: 'text-purple-700', border: 'border-purple-200' },
          expired: { bg: 'from-red-100 to-rose-100', text: 'text-red-700', border: 'border-red-200' },
        };
        const config = statusConfig[value] || { bg: 'from-gray-100 to-gray-200', text: 'text-gray-700', border: 'border-gray-300' };
        return (
          <span className={`px-3 py-1 rounded-full text-xs font-semibold bg-gradient-to-r ${config.bg} ${config.text} border ${config.border}`}>
            {value}
          </span>
        );
      },
    },
    {
      key: 'createdAt',
      label: 'Created',
      render: (value) => (
        <span className="text-sm text-gray-600">
          {new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
        </span>
      ),
    },
  ];

  const filters = [
    {
      key: 'type',
      label: 'Type',
      options: [
        { value: 'lost', label: 'Lost' },
        { value: 'found', label: 'Found' },
      ],
    },
    {
      key: 'status',
      label: 'Status',
      options: [
        { value: 'active', label: 'Active' },
        { value: 'claimed', label: 'Claimed' },
        { value: 'expired', label: 'Expired' },
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
          Posts Management
        </h1>
        <p className="text-gray-600 mt-1">Manage all lost and found posts</p>
      </motion.div>

      {/* Posts Table */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
      >
        <Table
          columns={columns}
          data={postsData?.posts || []}
          loading={isLoading}
          searchable
          filterable
          filters={filters}
          activeFilters={activeFilters}
          onFilterChange={(key, value) => setActiveFilters({ ...activeFilters, [key]: value })}
          onExport={handleExport}
          actions={(row) => (
            <>
              <motion.button
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => handleViewPost(row)}
                className="p-2 hover:bg-blue-50 rounded-lg transition-colors"
                title="View Details"
              >
                <Eye className="w-4 h-4 text-blue-600" />
              </motion.button>

              {!row.isDeleted && (
                <motion.button
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => {
                    if (window.confirm('Are you sure you want to delete this post?')) {
                      deleteMutation.mutate(row.postId);
                    }
                  }}
                  className="p-2 hover:bg-red-50 rounded-lg transition-colors"
                  title="Delete Post"
                >
                  <Trash2 className="w-4 h-4 text-red-600" />
                </motion.button>
              )}

              {row.isDeleted && (
                <motion.button
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => restoreMutation.mutate(row.postId)}
                  className="p-2 hover:bg-blue-50 rounded-lg transition-colors"
                  title="Restore Post"
                >
                  <RotateCcw className="w-4 h-4 text-blue-600" />
                </motion.button>
              )}
            </>
          )}
        />
      </motion.div>

      {/* Post Detail Modal */}
      <AnimatePresence>
        {showDetailModal && selectedPost && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowDetailModal(false)}
              className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              onClick={(e) => e.stopPropagation()}
              className="relative bg-white rounded-2xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-hidden"
            >
              {/* Header */}
              <div className="bg-gradient-to-r from-blue-500 to-indigo-600 p-6 text-white">
                <button
                  onClick={() => setShowDetailModal(false)}
                  className="absolute top-4 right-4 p-2 hover:bg-white/20 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
                <div className="flex items-center gap-3">
                  <span className={`px-4 py-2 rounded-full text-sm font-bold ${
                    selectedPost.type === 'found' ? 'bg-green-500' : 'bg-blue-400'
                  }`}>
                    {selectedPost.type?.toUpperCase()}
                  </span>
                  <h3 className="text-2xl font-bold">{selectedPost.itemName}</h3>
                </div>
              </div>

              {/* Content */}
              <div className="p-6 space-y-6 overflow-y-auto max-h-[calc(90vh-120px)]">
                {/* Images Gallery */}
                {selectedPost.images && selectedPost.images.length > 0 && (
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                    {selectedPost.images.map((img, idx) => (
                      <motion.img
                        key={idx}
                        initial={{ opacity: 0, scale: 0.9 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ delay: idx * 0.1 }}
                        src={img}
                        alt={`Post image ${idx + 1}`}
                        className="w-full h-48 object-cover rounded-xl border-2 border-blue-100 shadow-md hover:scale-105 transition-transform"
                      />
                    ))}
                  </div>
                )}

                {/* Description */}
                <div className="p-4 bg-blue-50 rounded-xl border border-blue-100">
                  <p className="text-gray-700 leading-relaxed">{selectedPost.description}</p>
                </div>

                {/* Stats Grid */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="p-4 bg-gradient-to-br from-blue-50 to-cyan-50 rounded-xl border border-blue-100 text-center">
                    <p className="text-xs text-blue-600 font-semibold mb-1">CATEGORY</p>
                    <p className="text-sm font-bold text-gray-900 capitalize">{selectedPost.category || 'N/A'}</p>
                  </div>
                  <div className="p-4 bg-gradient-to-br from-green-50 to-emerald-50 rounded-xl border border-green-100 text-center">
                    <p className="text-xs text-green-600 font-semibold mb-1">STATUS</p>
                    <p className="text-sm font-bold text-gray-900 capitalize">{selectedPost.status}</p>
                  </div>
                  <div className="p-4 bg-gradient-to-br from-purple-50 to-indigo-50 rounded-xl border border-purple-100 text-center">
                    <p className="text-xs text-purple-600 font-semibold mb-1">CLAIMS</p>
                    <p className="text-sm font-bold text-gray-900">{selectedPost.totalClaims || 0}</p>
                  </div>
                  <div className="p-4 bg-gradient-to-br from-orange-50 to-amber-50 rounded-xl border border-orange-100 text-center">
                    <p className="text-xs text-orange-600 font-semibold mb-1">COMMENTS</p>
                    <p className="text-sm font-bold text-gray-900">{selectedPost.totalComments || 0}</p>
                  </div>
                </div>

                {/* Reward */}
                {selectedPost.rewardAmount && (
                  <div className="p-4 bg-gradient-to-r from-green-50 to-emerald-50 rounded-xl border-2 border-green-200">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-semibold text-green-700">Reward Amount</span>
                      <span className="text-2xl font-bold text-green-600 flex items-center gap-1">
                        <span className="font-bold text-2xl">Rs</span> {/* CHANGED: DollarSign -> Rs */}
                        {selectedPost.rewardAmount.toLocaleString()}
                      </span>
                    </div>
                  </div>
                )}

                {/* Location */}
                {selectedPost.location && (
                  <div className="p-4 bg-gradient-to-br from-purple-50 to-indigo-50 rounded-xl border border-purple-100">
                    <div className="flex items-start gap-3">
                      <MapPin className="w-5 h-5 text-purple-600 mt-1" />
                      <div>
                        <p className="text-sm font-semibold text-purple-900 mb-1">{selectedPost.location.name}</p>
                        <p className="text-xs text-gray-600">
                          Coordinates: {selectedPost.location.coordinates[1].toFixed(6)}, {selectedPost.location.coordinates[0].toFixed(6)}
                        </p>
                      </div>
                    </div>
                  </div>
                )}

                {/* Tags */}
                {selectedPost.tags && selectedPost.tags.length > 0 && (
                  <div className="flex flex-wrap gap-2">
                    {selectedPost.tags.map((tag, idx) => (
                      <span
                        key={idx}
                        className="px-3 py-1 bg-gradient-to-r from-blue-100 to-cyan-100 text-blue-700 rounded-full text-xs font-semibold border border-blue-200 flex items-center gap-1"
                      >
                        <Tag className="w-3 h-3" />
                        {tag}
                      </span>
                    ))}
                  </div>
                )}

                {/* Author Info */}
                <div className="p-4 bg-gradient-to-br from-gray-50 to-slate-50 rounded-xl border border-gray-200">
                  <p className="text-xs text-gray-500 font-semibold mb-3">POSTED BY</p>
                  <div className="flex items-center gap-4">
                    <img
                      src={selectedPost.userId?.profileImage}
                      alt={selectedPost.userId?.fullName}
                      className="w-14 h-14 rounded-full border-2 border-blue-300 shadow-md"
                      onError={(e) => {
                        e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(selectedPost.userId?.fullName || 'User')}&background=3b82f6&color=fff&size=128`;
                      }}
                    />
                    <div>
                      <p className="font-bold text-gray-900">{selectedPost.userId?.fullName || 'Anonymous'}</p>
                      <p className="text-sm text-gray-600">@{selectedPost.userId?.username || 'anonymous'}</p>
                      <p className="text-xs text-gray-500">{selectedPost.userId?.email}</p>
                    </div>
                  </div>
                </div>

                {/* Timestamps */}
                <div className="grid grid-cols-2 gap-4 text-sm text-gray-600 p-4 bg-gray-50 rounded-xl">
                  <div>
                    <span className="font-semibold">Created:</span>{' '}
                    {new Date(selectedPost.createdAt).toLocaleString()}
                  </div>
                  <div>
                    <span className="font-semibold">Updated:</span>{' '}
                    {new Date(selectedPost.updatedAt).toLocaleString()}
                  </div>
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </motion.div>
  );
};

export default Posts;
