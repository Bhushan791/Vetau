// lib/api.js - Handles ALL backend API calls for admin panel

import axios from 'axios';

// Create axios instance with base configuration
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000, // 30 seconds
});

// Request interceptor - Attach JWT token to all requests
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth-token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor - Handle errors globally
api.interceptors.response.use(
  (response) => response,
  (error) => {
    // Handle 401 Unauthorized - Clear auth and redirect to login
    if (error.response?.status === 401) {
      localStorage.removeItem('auth-token');
      localStorage.removeItem('auth-user');
      window.location.href = '/login';
    }
    
    // Handle 403 Forbidden
    if (error.response?.status === 403) {
      console.error('Access denied:', error.response.data.message);
    }

    return Promise.reject(error);
  }
);

// ==================== AUTH API ====================
export const authAPI = {
  // Login admin
  login: async (email, password) => {
    const response = await api.post('/users/login', { email, password });
    console.log("RAW RESPONSE: ", response)
    return response.data;
  },

  // Logout
  logout: async () => {
    const response = await api.post('/users/logout');
    return response.data;
  },
};

// ==================== DASHBOARD API ====================
export const dashboardAPI = {
  // Get dashboard statistics
  getStats: async () => {
    const response = await api.get('/admin/dashboard/stats');
    return response.data.data;
  },

  // Get dashboard charts data
  getCharts: async (days = 30) => {
    const response = await api.get('/admin/dashboard/charts', {
      params: { days },
    });
    return response.data.data;
  },

  // Get recent activity
  getActivity: async () => {
    const response = await api.get('/admin/dashboard/activity');
    return response.data.data;
  },
};

// ==================== USERS API ====================
export const usersAPI = {
  // Get all users with filters
  getAll: async (params = {}) => {
    const response = await api.get('/admin/users', { params });
    return response.data.data;
  },

  // Get single user details
  getById: async (userId) => {
    const response = await api.get(`/admin/users/${userId}`);
    return response.data.data;
  },

  // Ban user
  ban: async (userId, reason = '') => {
    const response = await api.patch(`/admin/users/${userId}/ban`, { reason });
    return response.data.data;
  },

  // Unban user
  unban: async (userId) => {
    const response = await api.patch(`/admin/users/${userId}/unban`);
    return response.data.data;
  },

  // Soft delete user
  softDelete: async (userId) => {
    const response = await api.delete(`/admin/users/${userId}`);
    return response.data;
  },

  // Restore user
  restore: async (userId) => {
    const response = await api.patch(`/admin/users/${userId}/restore`);
    return response.data.data;
  },

  // Export users to CSV
  export: async (params = {}) => {
    const response = await api.get('/admin/users/export/csv', { params });
    return response.data.data;
  },
};

// ==================== POSTS API ====================
export const postsAPI = {
  // Get all posts with filters
  getAll: async (params = {}) => {
    const response = await api.get('/admin/posts', { params });
    return response.data.data;
  },

  // Get single post details
  getById: async (postId) => {
    const response = await api.get(`/admin/posts/${postId}`);
    return response.data.data;
  },

  // Soft delete post
  softDelete: async (postId) => {
    const response = await api.delete(`/admin/posts/${postId}`);
    return response.data;
  },

  // Restore post
  restore: async (postId) => {
    const response = await api.patch(`/admin/posts/${postId}/restore`);
    return response.data.data;
  },

  // Export posts to CSV
  export: async (params = {}) => {
    const response = await api.get('/admin/posts/export/csv', { params });
    return response.data.data;
  },
};

// ==================== CLAIMS API ====================
export const claimsAPI = {
  // Get claims analytics overview
  getAnalytics: async () => {
    const response = await api.get('/admin/claims/analytics');
    return response.data.data;
  },

  // Get claims trend (daily/weekly/monthly)
  getTrend: async (period = 30) => {
    const response = await api.get('/admin/claims/trend', {
      params: { period },
    });
    return response.data.data;
  },

  // Get top claimers leaderboard
  getTopUsers: async (limit = 10) => {
    const response = await api.get('/admin/claims/top-users', {
      params: { limit },
    });
    return response.data.data;
  },
};

// ==================== CATEGORIES API ====================
export const categoriesAPI = {
  // Get all categories
  getAll: async () => {
    const response = await api.get('/categories');
    return response.data.data;
  },

  // Get single category
  getById: async (categoryId) => {
    const response = await api.get(`/categories/${categoryId}`);
    return response.data.data;
  },

  // Create new category
  create: async (data) => {
    const response = await api.post('/categories', data);
    return response.data.data;
  },

  // Update category
  update: async (categoryId, data) => {
    const response = await api.patch(`/categories/${categoryId}`, data);
    return response.data.data;
  },

  // Delete category
  delete: async (categoryId) => {
    const response = await api.delete(`/categories/${categoryId}`);
    return response.data;
  },
};

// ==================== REPORTS API ====================
export const reportsAPI = {
  // User analytics report
  users: async (period = 30) => {
    const response = await api.get('/admin/reports/users', {
      params: { period },
    });
    return response.data.data;
  },

  // Post analytics report
  posts: async (period = 30) => {
    const response = await api.get('/admin/reports/posts', {
      params: { period },
    });
    return response.data.data;
  },

  // Revenue analytics report
  revenue: async (period = 30) => {
    const response = await api.get('/admin/reports/revenue', {
      params: { period },
    });
    return response.data.data;
  },

  // Engagement analytics report
  engagement: async (period = 30) => {
    const response = await api.get('/admin/reports/engagement', {
      params: { period },
    });
    return response.data.data;
  },
};

// Export default api instance for custom requests
export default api;