// pages/Reports.jsx - FULLY FIXED with Correct Data Mapping

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { Users, FileText, DollarSign, MessageSquare, TrendingUp, Award } from 'lucide-react';
import { LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import StatsCard from '../components/StatsCard';
import { reportsAPI } from '../lib/api';

const Reports = () => {
  const [activeTab, setActiveTab] = useState('users');
  const [period, setPeriod] = useState(30);

  // Fetch reports based on active tab
  const { data: usersReport, isLoading: usersLoading } = useQuery({
    queryKey: ['reports-users', period],
    queryFn: () => reportsAPI.users(period),
    enabled: activeTab === 'users',
  });

  const { data: postsReport, isLoading: postsLoading } = useQuery({
    queryKey: ['reports-posts', period],
    queryFn: () => reportsAPI.posts(period),
    enabled: activeTab === 'posts',
  });

  const { data: revenueReport, isLoading: revenueLoading } = useQuery({
    queryKey: ['reports-revenue', period],
    queryFn: () => reportsAPI.revenue(period),
    enabled: activeTab === 'revenue',
  });

  const { data: engagementReport, isLoading: engagementLoading } = useQuery({
    queryKey: ['reports-engagement', period],
    queryFn: () => reportsAPI.engagement(period),
    enabled: activeTab === 'engagement',
  });

  const tabs = [
    { id: 'users', label: 'Users', icon: Users, color: 'blue' },
    { id: 'posts', label: 'Posts', icon: FileText, color: 'purple' },
    { id: 'revenue', label: 'Revenue', icon: DollarSign, color: 'green' },
    { id: 'engagement', label: 'Engagement', icon: MessageSquare, color: 'orange' },
  ];

  const periods = [
    { value: 7, label: '7 Days' },
    { value: 30, label: '30 Days' },
    { value: 90, label: '90 Days' },
  ];

  const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899'];

  return (
    <div className="space-y-6 p-6">
      {/* Page Header */}
      <motion.div 
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex items-center justify-between"
      >
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Reports & Analytics</h1>
          <p className="text-gray-600 mt-1">Comprehensive insights and data analysis</p>
        </div>

        {/* Period Selector */}
        <select
          value={period}
          onChange={(e) => setPeriod(Number(e.target.value))}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white shadow-sm"
        >
          {periods.map((p) => (
            <option key={p.value} value={p.value}>
              Last {p.label}
            </option>
          ))}
        </select>
      </motion.div>

      {/* Tabs */}
      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="bg-white rounded-xl shadow-sm border border-gray-100 p-2"
      >
        <div className="grid grid-cols-4 gap-2">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center justify-center gap-2 px-4 py-3 rounded-lg font-medium transition-all ${
                activeTab === tab.id
                  ? `bg-${tab.color}-500 text-white shadow-lg`
                  : 'text-gray-600 hover:bg-gray-100'
              }`}
              style={activeTab === tab.id ? {
                backgroundColor: tab.color === 'blue' ? '#3b82f6' : 
                                 tab.color === 'purple' ? '#8b5cf6' :
                                 tab.color === 'green' ? '#10b981' : '#f59e0b'
              } : {}}
            >
              <tab.icon className="w-5 h-5" />
              <span>{tab.label}</span>
            </button>
          ))}
        </div>
      </motion.div>

      {/* Tab Content */}
      <AnimatePresence mode="wait">
        <motion.div
          key={activeTab}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
          transition={{ duration: 0.3 }}
        >
          {/* ==================== USERS TAB ==================== */}
          {activeTab === 'users' && (
            <div className="space-y-6">
              {/* Stats Cards */}
              <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                <StatsCard
                  icon={Users}
                  label="Total Users"
                  value={usersReport?.totalUsers || 0}
                  change={parseFloat(usersReport?.growthRate) || 0}
                  color="blue"
                  loading={usersLoading}
                />
                <StatsCard
                  icon={TrendingUp}
                  label="New Users"
                  value={usersReport?.newUsers || 0}
                  color="green"
                  loading={usersLoading}
                />
                <StatsCard
                  icon={Users}
                  label="Active (7d)"
                  value={usersReport?.activeUsersLast7Days || 0}
                  color="purple"
                  loading={usersLoading}
                />
                <StatsCard
                  icon={Award}
                  label="Retention Rate"
                  value={usersReport?.retentionRate || '0%'}
                  color="orange"
                  loading={usersLoading}
                />
              </div>

              {/* Charts Row 1 */}
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Registration Trend Line Chart */}
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                  <h3 className="text-lg font-semibold text-gray-900 mb-4">User Registrations Over Time</h3>
                  {usersLoading ? (
                    <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
                  ) : usersReport?.registrationTrend?.length > 0 ? (
                    <ResponsiveContainer width="100%" height={300}>
                      <LineChart data={usersReport.registrationTrend}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                        <XAxis dataKey="_id" stroke="#9ca3af" fontSize={12} />
                        <YAxis stroke="#9ca3af" fontSize={12} />
                        <Tooltip />
                        <Line type="monotone" dataKey="count" stroke="#3b82f6" strokeWidth={3} dot={{ fill: '#3b82f6' }} />
                      </LineChart>
                    </ResponsiveContainer>
                  ) : (
                    <div className="h-64 flex items-center justify-center text-gray-400">No data available</div>
                  )}
                </div>

                {/* Auth Distribution Pie Chart */}
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                  <h3 className="text-lg font-semibold text-gray-900 mb-4">Authentication Methods</h3>
                  {usersLoading ? (
                    <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
                  ) : usersReport?.authDistribution?.length > 0 ? (
                    <ResponsiveContainer width="100%" height={300}>
                      <PieChart>
                        <Pie
                          data={usersReport.authDistribution}
                          cx="50%"
                          cy="50%"
                          labelLine={false}
                          label={({ _id, count }) => `${_id}: ${count}`}
                          outerRadius={100}
                          dataKey="count"
                        >
                          {usersReport.authDistribution.map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                          ))}
                        </Pie>
                        <Tooltip />
                        <Legend />
                      </PieChart>
                    </ResponsiveContainer>
                  ) : (
                    <div className="h-64 flex items-center justify-center text-gray-400">No data available</div>
                  )}
                </div>
              </div>

              {/* Status Distribution Bar Chart */}
              <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">User Status Distribution</h3>
                {usersLoading ? (
                  <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
                ) : usersReport?.statusDistribution?.length > 0 ? (
                  <ResponsiveContainer width="100%" height={300}>
                    <BarChart data={usersReport.statusDistribution}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                      <XAxis dataKey="_id" stroke="#9ca3af" fontSize={12} />
                      <YAxis stroke="#9ca3af" fontSize={12} />
                      <Tooltip />
                      <Bar dataKey="count" radius={[8, 8, 0, 0]}>
                        {usersReport.statusDistribution.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry._id === 'active' ? '#10b981' : '#ef4444'} />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                ) : (
                  <div className="h-64 flex items-center justify-center text-gray-400">No data available</div>
                )}
              </div>

              {/* Top Contributors */}
              {usersReport?.topContributors?.length > 0 && (
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                  <h3 className="text-lg font-semibold text-gray-900 mb-6">Top Contributors</h3>
                  <div className="space-y-3">
                    {usersReport.topContributors.slice(0, 5).map((user, index) => (
                      <motion.div
                        key={user._id}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: index * 0.05 }}
                        className="flex items-center gap-4 p-4 hover:bg-gray-50 rounded-lg transition-colors"
                      >
                        <div className={`w-10 h-10 rounded-lg flex items-center justify-center font-bold text-lg ${
                          index === 0 ? 'bg-yellow-400 text-white' :
                          index === 1 ? 'bg-gray-300 text-white' :
                          index === 2 ? 'bg-orange-400 text-white' :
                          'bg-gray-100 text-gray-700'
                        }`}>
                          {index + 1}
                        </div>
                        <img
                          src={user.profileImage}
                          alt={user.fullName}
                          className="w-12 h-12 rounded-full"
                        />
                        <div className="flex-1">
                          <p className="font-semibold text-gray-900">{user.fullName}</p>
                          <p className="text-sm text-gray-500">@{user.username}</p>
                        </div>
                        <div className="text-right">
                          <p className="text-2xl font-bold text-blue-600">{user.totalPosts}</p>
                          <p className="text-xs text-gray-500">posts</p>
                        </div>
                      </motion.div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* ==================== POSTS TAB ==================== */}
          {activeTab === 'posts' && (
            <div className="space-y-6">
              {/* Stats Cards */}
              <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                <StatsCard
                  icon={FileText}
                  label="Total Posts"
                  value={postsReport?.totalPosts || 0}
                  color="purple"
                  loading={postsLoading}
                />
                <StatsCard
                  icon={TrendingUp}
                  label="New Posts"
                  value={postsReport?.newPosts || 0}
                  color="blue"
                  loading={postsLoading}
                />
                <StatsCard
                  icon={Award}
                  label="Lost Posts"
                  value={postsReport?.typeDistribution?.find(t => t._id === 'lost')?.count || 0}
                  color="orange"
                  loading={postsLoading}
                />
                <StatsCard
                  icon={Award}
                  label="Found Posts"
                  value={postsReport?.typeDistribution?.find(t => t._id === 'found')?.count || 0}
                  color="green"
                  loading={postsLoading}
                />
              </div>

              {/* Charts Row 1 */}
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Posts Trend */}
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                  <h3 className="text-lg font-semibold text-gray-900 mb-4">Posts Created Over Time</h3>
                  {postsLoading ? (
                    <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
                  ) : postsReport?.postsTrend?.length > 0 ? (
                    <ResponsiveContainer width="100%" height={300}>
                      <LineChart data={postsReport.postsTrend}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                        <XAxis dataKey="_id" stroke="#9ca3af" fontSize={12} />
                        <YAxis stroke="#9ca3af" fontSize={12} />
                        <Tooltip />
                        <Legend />
                        <Line type="monotone" dataKey="total" stroke="#8b5cf6" strokeWidth={2} name="Total" />
                        <Line type="monotone" dataKey="lost" stroke="#f59e0b" strokeWidth={2} name="Lost" />
                        <Line type="monotone" dataKey="found" stroke="#10b981" strokeWidth={2} name="Found" />
                      </LineChart>
                    </ResponsiveContainer>
                  ) : (
                    <div className="h-64 flex items-center justify-center text-gray-400">No data available</div>
                  )}
                </div>

                {/* Type Distribution */}
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                  <h3 className="text-lg font-semibold text-gray-900 mb-4">Posts by Type</h3>
                  {postsLoading ? (
                    <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
                  ) : postsReport?.typeDistribution?.length > 0 ? (
                    <ResponsiveContainer width="100%" height={300}>
                      <PieChart>
                        <Pie
                          data={postsReport.typeDistribution}
                          cx="50%"
                          cy="50%"
                          labelLine={false}
                          label={({ _id, count }) => `${_id}: ${count}`}
                          outerRadius={100}
                          dataKey="count"
                        >
                          {postsReport.typeDistribution.map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={entry._id === 'lost' ? '#f59e0b' : '#10b981'} />
                          ))}
                        </Pie>
                        <Tooltip />
                        <Legend />
                      </PieChart>
                    </ResponsiveContainer>
                  ) : (
                    <div className="h-64 flex items-center justify-center text-gray-400">No data available</div>
                  )}
                </div>
              </div>

              {/* Category Distribution */}
              <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Posts by Category</h3>
                {postsLoading ? (
                  <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
                ) : postsReport?.categoryDistribution?.length > 0 ? (
                  <ResponsiveContainer width="100%" height={300}>
                    <BarChart data={postsReport.categoryDistribution}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                      <XAxis dataKey="_id" stroke="#9ca3af" fontSize={12} />
                      <YAxis stroke="#9ca3af" fontSize={12} />
                      <Tooltip />
                      <Bar dataKey="count" fill="#8b5cf6" radius={[8, 8, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                ) : (
                  <div className="h-64 flex items-center justify-center text-gray-400">No data available</div>
                )}
              </div>
            </div>
          )}

          {/* ==================== REVENUE TAB ==================== */}
          {activeTab === 'revenue' && (
            <div className="space-y-6">
              {/* Stats Cards */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <StatsCard
                  icon={DollarSign}
                  label="Total Revenue"
                  value={revenueReport?.totalRevenue || '₹0'}
                  color="green"
                  loading={revenueLoading}
                />
                <StatsCard
                  icon={TrendingUp}
                  label="Period Revenue"
                  value={revenueReport?.periodRevenue || '₹0'}
                  color="blue"
                  loading={revenueLoading}
                />
                <StatsCard
                  icon={Award}
                  label="High Value Posts"
                  value={revenueReport?.highValuePosts || 0}
                  color="purple"
                  loading={revenueLoading}
                />
              </div>

              {/* Charts */}
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Revenue Trend */}
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                  <h3 className="text-lg font-semibold text-gray-900 mb-4">Revenue Trend</h3>
                  {revenueLoading ? (
                    <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
                  ) : revenueReport?.revenueTrend?.length > 0 ? (
                    <ResponsiveContainer width="100%" height={300}>
                      <LineChart data={revenueReport.revenueTrend}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                        <XAxis dataKey="_id" stroke="#9ca3af" fontSize={12} />
                        <YAxis stroke="#9ca3af" fontSize={12} />
                        <Tooltip formatter={(value) => `₹${value}`} />
                        <Line type="monotone" dataKey="totalRevenue" stroke="#10b981" strokeWidth={3} dot={{ fill: '#10b981' }} />
                      </LineChart>
                    </ResponsiveContainer>
                  ) : (
                    <div className="h-64 flex items-center justify-center text-gray-400">No data available</div>
                  )}
                </div>

                {/* Reward Distribution */}
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                  <h3 className="text-lg font-semibold text-gray-900 mb-4">Reward Distribution</h3>
                  {revenueLoading ? (
                    <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
                  ) : revenueReport?.rewardDistribution?.length > 0 ? (
                    <ResponsiveContainer width="100%" height={300}>
                      <BarChart data={revenueReport.rewardDistribution}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                        <XAxis dataKey="_id" stroke="#9ca3af" fontSize={12} tickFormatter={(value) => `₹${value}`} />
                        <YAxis stroke="#9ca3af" fontSize={12} />
                        <Tooltip formatter={(value) => `${value} posts`} />
                        <Bar dataKey="count" fill="#f59e0b" radius={[8, 8, 0, 0]} />
                      </BarChart>
                    </ResponsiveContainer>
                  ) : (
                    <div className="h-64 flex items-center justify-center text-gray-400">No data available</div>
                  )}
                </div>
              </div>

              {/* Avg Reward by Category */}
              <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Average Reward by Category</h3>
                {revenueLoading ? (
                  <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
                ) : revenueReport?.avgRewardByCategory?.length > 0 ? (
                  <ResponsiveContainer width="100%" height={300}>
                    <BarChart data={revenueReport.avgRewardByCategory}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                      <XAxis dataKey="_id" stroke="#9ca3af" fontSize={12} />
                      <YAxis stroke="#9ca3af" fontSize={12} />
                      <Tooltip formatter={(value) => `₹${value.toFixed(0)}`} />
                      <Bar dataKey="avgReward" fill="#8b5cf6" radius={[8, 8, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                ) : (
                  <div className="h-64 flex items-center justify-center text-gray-400">No data available</div>
                )}
              </div>
            </div>
          )}

          {/* ==================== ENGAGEMENT TAB ==================== */}
          {activeTab === 'engagement' && (
            <div className="space-y-6">
              {/* Stats Cards */}
              <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                <StatsCard
                  icon={MessageSquare}
                  label="Total Comments"
                  value={engagementReport?.totalComments || 0}
                  color="blue"
                  loading={engagementLoading}
                />
                <StatsCard
                  icon={TrendingUp}
                  label="Period Comments"
                  value={engagementReport?.periodComments || 0}
                  color="green"
                  loading={engagementLoading}
                />
                <StatsCard
                  icon={MessageSquare}
                  label="Total Messages"
                  value={engagementReport?.totalMessages || 0}
                  color="purple"
                  loading={engagementLoading}
                />
                <StatsCard
                  icon={Award}
                  label="Avg Comments/Post"
                  value={engagementReport?.avgCommentsPerPost || '0'}
                  color="orange"
                  loading={engagementLoading}
                />
              </div>

              {/* Empty State */}
              {!engagementLoading && engagementReport?.totalComments === 0 && engagementReport?.totalMessages === 0 ? (
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-12 text-center">
                  <MessageSquare className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                  <h3 className="text-xl font-semibold text-gray-700 mb-2">No Engagement Data Yet</h3>
                  <p className="text-gray-500">Comments and messages will appear here once users start engaging</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  {/* Comment Trend */}
                  <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-4">Comment Activity</h3>
                    {engagementLoading ? (
                      <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
                    ) : engagementReport?.commentTrend?.length > 0 ? (
                      <ResponsiveContainer width="100%" height={300}>
                        <LineChart data={engagementReport.commentTrend}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="_id" stroke="#9ca3af" fontSize={12} />
                          <YAxis stroke="#9ca3af" fontSize={12} />
                          <Tooltip />
                          <Line type="monotone" dataKey="count" stroke="#3b82f6" strokeWidth={3} />
                        </LineChart>
                      </ResponsiveContainer>
                    ) : (
                      <div className="h-64 flex items-center justify-center text-gray-400">No data available</div>
                    )}
                  </div>

                  {/* Top Commenters */}
                  <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-4">Top Commenters</h3>
                    {engagementLoading ? (
                      <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
                    ) : engagementReport?.topCommenters?.length > 0 ? (
                      <div className="space-y-3">
                        {engagementReport.topCommenters.slice(0, 5).map((user, index) => (
                          <div key={user.userId} className="flex items-center gap-3 p-3 hover:bg-gray-50 rounded-lg">
                            <div className={`w-8 h-8 rounded flex items-center justify-center font-bold text-sm ${
                              index === 0 ? 'bg-yellow-400 text-white' :
                              index === 1 ? 'bg-gray-300 text-white' :
                              'bg-gray-100 text-gray-700'
                            }`}>
                              {index + 1}
                            </div>
                            <div className="flex-1">
                              <p className="font-medium text-gray-900">{user.fullName}</p>
                              <p className="text-sm text-gray-500">@{user.username}</p>
                            </div>
                            <div className="text-right">
                              <p className="text-lg font-bold text-blue-600">{user.commentCount}</p>
                              <p className="text-xs text-gray-500">comments</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <div className="h-64 flex items-center justify-center text-gray-400">No commenters yet</div>
                    )}
                  </div>
                </div>
              )}
            </div>
          )}
        </motion.div>
      </AnimatePresence>
    </div>
  );
};

export default Reports;