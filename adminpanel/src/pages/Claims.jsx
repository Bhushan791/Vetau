// pages/Claims.jsx - BULLETPROOF, SAFE, SMOOTH

import { useQuery } from '@tanstack/react-query';
import { Award, TrendingUp, CheckCircle, XCircle, Clock, Target } from 'lucide-react';
import { motion } from 'framer-motion';
import { LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import StatsCard from '../components/StatsCard';
import { claimsAPI } from '../lib/api';

const Claims = () => {
  // ------------------ Data Fetching ------------------
  const { data: analytics, isLoading: analyticsLoading, error: analyticsError } = useQuery({
    queryKey: ['claims-analytics'],
    queryFn: claimsAPI.getAnalytics,
  });

  const { data: trendResponse, isLoading: trendLoading, error: trendError } = useQuery({
    queryKey: ['claims-trend'],
    queryFn: () => claimsAPI.getTrend(30),
  });

  const { data: topUsers, isLoading: topUsersLoading, error: topUsersError } = useQuery({
    queryKey: ['claims-top-users'],
    queryFn: () => claimsAPI.getTopUsers(10),
  });

  // ------------------ Safe Data Extraction ------------------
  const totalClaims = Number(analytics?.totalClaims || 0);
  const acceptedClaims = Number(analytics?.statusBreakdown?.accepted || 0);
  const pendingClaims = Number(analytics?.statusBreakdown?.pending || 0);
  const rejectedClaims = Number(analytics?.statusBreakdown?.rejected || 0);
  const successRate = analytics?.successRate || '0%';
  const avgResponseTime = analytics?.avgResponseTime || 'N/A';

  // Line Chart - Claims Trend
  const trendData = Array.isArray(trendResponse?.claimsTrend)
    ? trendResponse.claimsTrend.map(item => ({
        date: (item._id || '').substring(5, 10),
        total: Number(item.total || 0),
      }))
    : [];

  // Bar Chart - Acceptance Rate
  const acceptanceData = Array.isArray(trendResponse?.acceptanceRateTrend)
    ? trendResponse.acceptanceRateTrend.map(item => ({
        date: (item.date || '').substring(5, 10),
        rate: Number(item.acceptanceRate || 0),
      }))
    : [];

  // Pie Chart - Status Distribution
  const statusData = [
    { name: 'Accepted', value: acceptedClaims, color: '#10b981' },
    { name: 'Pending', value: pendingClaims, color: '#f59e0b' },
    { name: 'Rejected', value: rejectedClaims, color: '#ef4444' },
  ].filter(item => item.value > 0);

  const safeTopUsers = Array.isArray(topUsers) ? topUsers : [];

  // ------------------ Error Handling ------------------
  if (analyticsError || trendError || topUsersError) {
    return (
      <div className="space-y-6 p-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Claims Analytics</h1>
          <p className="text-gray-600 mt-1">Track and analyze claim activities</p>
        </div>
        <div className="bg-red-50 border border-red-200 rounded-xl p-6">
          <p className="text-red-600 font-semibold text-lg">Failed to load claims data</p>
          <p className="text-red-500 text-sm mt-2">
            {analyticsError?.message || trendError?.message || topUsersError?.message || 'Unknown error'}
          </p>
        </div>
      </div>
    );
  }

  // ------------------ Animation Variants ------------------
  const fadeUp = { initial: { opacity: 0, y: 20 }, animate: { opacity: 1, y: 0 }, transition: { duration: 0.5 } };

  // ------------------ Main UI ------------------
  return (
    <div className="space-y-6 p-6">
      {/* Page Header */}
      <motion.div {...fadeUp}>
        <h1 className="text-3xl font-bold text-gray-900">Claims Analytics</h1>
        <p className="text-gray-600 mt-1">Track and analyze claim activities</p>
      </motion.div>

      {/* Stats Cards */}
      <motion.div {...fadeUp} className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatsCard icon={Award} label="Total Claims" value={totalClaims} change={0} color="purple" loading={analyticsLoading} />
        <StatsCard icon={CheckCircle} label="Accepted" value={acceptedClaims} change={0} color="green" loading={analyticsLoading} />
        <StatsCard icon={TrendingUp} label="Pending" value={pendingClaims} change={0} color="orange" loading={analyticsLoading} />
        <StatsCard icon={XCircle} label="Rejected" value={rejectedClaims} change={0} color="red" loading={analyticsLoading} />
      </motion.div>

      {/* Success Rate & Avg Response */}
      <motion.div {...fadeUp} className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Success Rate Card */}
        <div className="bg-gradient-to-br from-green-50 to-emerald-100 rounded-xl shadow-sm border border-green-200 p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-green-500 rounded-lg flex items-center justify-center">
              <Target className="w-6 h-6 text-white" />
            </div>
            <div>
              <p className="text-sm font-medium text-green-700">Success Rate</p>
              <p className="text-xs text-green-600">Claims accepted vs total</p>
            </div>
          </div>
          {analyticsLoading ? (
            <div className="h-12 bg-green-200 rounded animate-pulse"></div>
          ) : (
            <p className="text-5xl font-bold text-green-900">{successRate}</p>
          )}
        </div>

        {/* Avg Response Time Card */}
        <div className="bg-gradient-to-br from-blue-50 to-indigo-100 rounded-xl shadow-sm border border-blue-200 p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-blue-500 rounded-lg flex items-center justify-center">
              <Clock className="w-6 h-6 text-white" />
            </div>
            <div>
              <p className="text-sm font-medium text-blue-700">Avg Response Time</p>
              <p className="text-xs text-blue-600">Time to accept/reject</p>
            </div>
          </div>
          {analyticsLoading ? (
            <div className="h-12 bg-blue-200 rounded animate-pulse"></div>
          ) : (
            <p className="text-5xl font-bold text-blue-900">{avgResponseTime}</p>
          )}
        </div>
      </motion.div>

      {/* Charts */}
      <motion.div {...fadeUp} className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Line Chart */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Claims Trend (Last 30 Days)</h3>
          {trendLoading ? (
            <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
          ) : trendData.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={trendData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="date" stroke="#9ca3af" fontSize={12} />
                <YAxis stroke="#9ca3af" fontSize={12} />
                <Tooltip contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
                <Line type="monotone" dataKey="total" stroke="#8b5cf6" strokeWidth={3} dot={{ fill: '#8b5cf6', r: 4 }} />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-64 flex items-center justify-center text-gray-400">No data available</div>
          )}
        </div>

        {/* Pie Chart */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Claim Status Distribution</h3>
          {analyticsLoading ? (
            <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
          ) : statusData.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={statusData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                  outerRadius={100}
                  dataKey="value"
                >
                  {statusData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
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
      </motion.div>

      {/* Bar Chart */}
      <motion.div {...fadeUp} className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Acceptance Rate Over Time (%)</h3>
        {trendLoading ? (
          <div className="h-64 bg-gray-100 rounded animate-pulse"></div>
        ) : acceptanceData.length > 0 ? (
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={acceptanceData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="date" stroke="#9ca3af" fontSize={12} />
              <YAxis stroke="#9ca3af" fontSize={12} />
              <Tooltip contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }} />
              <Bar dataKey="rate" fill="#10b981" radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        ) : (
          <div className="h-64 flex items-center justify-center text-gray-400">No data available</div>
        )}
      </motion.div>

      {/* Top Claimers Leaderboard */}
      <motion.div {...fadeUp} className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-semibold text-gray-900">Top Claimers Leaderboard</h3>
          <div className="text-sm text-gray-500">Last 30 days</div>
        </div>

        {topUsersLoading ? (
          <div className="space-y-4">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="flex items-center gap-4 animate-pulse">
                <div className="w-10 h-10 bg-gray-200 rounded-lg"></div>
                <div className="w-12 h-12 bg-gray-200 rounded-full"></div>
                <div className="flex-1 space-y-2">
                  <div className="h-4 bg-gray-200 rounded w-1/3"></div>
                  <div className="h-3 bg-gray-200 rounded w-1/4"></div>
                </div>
                <div className="h-10 bg-gray-200 rounded w-24"></div>
              </div>
            ))}
          </div>
        ) : safeTopUsers.length > 0 ? (
          <div className="space-y-3">
            {safeTopUsers.map((user, index) => (
              <motion.div
                key={user.userId || index}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.05, duration: 0.4 }}
                className="flex items-center gap-4 p-4 hover:bg-gradient-to-r hover:from-purple-50 hover:to-pink-50 rounded-lg transition-all duration-300 group"
              >
                {/* Rank Badge */}
                <div
                  className={`w-10 h-10 rounded-lg flex items-center justify-center font-bold text-lg shadow-sm ${
                    index === 0
                      ? 'bg-gradient-to-br from-yellow-400 to-yellow-600 text-white'
                      : index === 1
                      ? 'bg-gradient-to-br from-gray-300 to-gray-500 text-white'
                      : index === 2
                      ? 'bg-gradient-to-br from-orange-400 to-orange-600 text-white'
                      : 'bg-gradient-to-br from-gray-100 to-gray-200 text-gray-700'
                  }`}
                >
                  {index + 1}
                </div>

                {/* Avatar */}
                <div className="relative">
                  <div className="w-12 h-12 bg-gradient-to-br from-purple-500 to-pink-500 rounded-full flex items-center justify-center text-white font-bold text-lg shadow-md group-hover:scale-110 transition-transform duration-300">
                    {user?.fullName?.charAt(0)?.toUpperCase() || 'U'}
                  </div>
                  {index < 3 && (
                    <div className="absolute -top-1 -right-1 w-5 h-5 bg-yellow-400 rounded-full flex items-center justify-center text-xs">
                      ⭐
                    </div>
                  )}
                </div>

                {/* User Info */}
                <div className="flex-1">
                  <p className="font-semibold text-gray-900 group-hover:text-purple-600 transition-colors">
                    {user?.fullName || 'Unknown User'}
                  </p>
                  <p className="text-sm text-gray-500">{user?.email || 'No email'}</p>
                </div>

                {/* Stats */}
                <div className="text-right">
                  <p className="text-3xl font-bold text-purple-600">{Number(user?.totalClaims || 0)}</p>
                  <div className="mt-1 px-2 py-1 bg-green-100 rounded text-xs font-medium text-green-700">
                    {typeof user?.successRate === 'number' ? user.successRate.toFixed(1) : 0}% success
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        ) : (
          <div className="text-center py-16">
            <div className="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Award className="w-10 h-10 text-gray-400" />
            </div>
            <p className="text-gray-500 font-medium">No claimers data available yet</p>
            <p className="text-sm text-gray-400 mt-1">Claims will appear here once users start claiming items</p>
          </div>
        )}
      </motion.div>
    </div>
  );
};

export default Claims;
