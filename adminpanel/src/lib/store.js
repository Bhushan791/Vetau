// lib/store.js - Zustand Auth Store (NO PERSIST - MANUAL ONLY)

import { create } from 'zustand';

export const useAuthStore = create((set, get) => ({
  // State
  user: null,
  token: null,
  isAuthenticated: false,
  isLoading: true, 

  // Actions
  login: (userData, token) => {
    console.log('🔐 LOGIN CALLED:', { userData, token });
    localStorage.setItem('auth-token', token);
    localStorage.setItem('auth-user', JSON.stringify(userData));
    set({
      user: userData,
      token: token,
      isAuthenticated: true,
      isLoading: false,
    });
  },

  logout: () => {
    console.log('🚪 LOGOUT CALLED');
    localStorage.removeItem('auth-token');
    localStorage.removeItem('auth-user');
    set({
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,
    });
  },

  // ✅ CHECK AUTH FROM LOCALSTORAGE ON APP LOAD
  checkAuth: () => {
    console.log('🔍 CHECK AUTH CALLED');
    const token = localStorage.getItem('auth-token');
    const userStr = localStorage.getItem('auth-user');
    
    console.log('📦 Found in localStorage:', { token: !!token, user: !!userStr });
    
    if (token && userStr) {
      try {
        const user = JSON.parse(userStr);
        console.log('✅ AUTH RESTORED:', user);
        set({
          user: user,
          token: token,
          isAuthenticated: true,
          isLoading: false,
        });
      } catch (error) {
        console.error('❌ Parse error:', error);
        get().logout();
        set({ isLoading: false });
      }
    } else {
      console.log('❌ NO AUTH FOUND');
      set({ 
        user: null,
        token: null,
        isAuthenticated: false,
        isLoading: false 
      });
    }
  },

  setLoading: (isLoading) => {
    set({ isLoading });
  },
}));

// Selectors
export const selectUser = (state) => state.user;
export const selectToken = (state) => state.token;
export const selectIsAuthenticated = (state) => state.isAuthenticated;
export const selectIsLoading = (state) => state.isLoading;