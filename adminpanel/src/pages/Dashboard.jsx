// pages/Dashboard.jsx - ULTIMATE ADMIN DASHBOARD (PERFECT VERSION)

import { useQuery } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { Users, FileText, Award, TrendingUp, Clock, CheckCircle, XCircle, UserPlus, Upload } from 'lucide-react';
import StatsCard from '../components/StatsCard';
import Chart from '../components/Chart';
import { dashboardAPI } from '../lib/api';

const Dashboard = () => {
  // Fetch dashboard stats
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: dashboardAPI.getStats,
  });

  // Fetch dashboard charts
  const { data: charts, isLoading: chartsLoading } = useQuery({
    queryKey: ['dashboard-charts'],
    queryFn: () => dashboardAPI.getCharts(30),
  });

  // Fetch recent activity
  const { data: activity, isLoading: activityLoading } = useQuery({
    queryKey: ['dashboard-activity'],
    queryFn: dashboardAPI.getActivity,
  });

  // Parse growth percentage
  const parseGrowth = (growthStr) => {
    if (!growthStr) return 0;
    return parseFloat(growthStr.replace('%', ''));
  };

  // Transform activity data
  const transformActivityData = (activityData) => {
    if (!activityData) return [];
    
    const activities = [];
    
    // Add recent users
    if (activityData.recentUsers) {
      activityData.recentUsers.slice(0, 5).forEach(user => {
        activities.push({
          type: 'user',
          title: 'New User Registered',
          description: `${user.fullName} (@${user.username}) joined the platform`,
          timestamp: new Date(user.createdAt).toLocaleString(),
          avatar: user.profileImage,
          icon: UserPlus
        });
      });
    }
    
    // Add recent posts
    if (activityData.recentPosts) {
      activityData.recentPosts.slice(0, 5).forEach(post => {
        activities.push({
          type: 'post',
          title: `New ${post.type === 'lost' ? 'Lost' : 'Found'} Post`,
          description: `${post.userId?.fullName} posted: ${post.itemName}`,
          timestamp: new Date(post.createdAt).toLocaleString(),
          avatar: post.userId?.profileImage,
          icon: Upload
        });
      });
    }
    
    // Sort by timestamp (most recent first)
    return activities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp)).slice(0, 10);
  };

  const activityFeed = transformActivityData(activity);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.3 }}
      className="space-y-6"
    >
      {/* Page Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
          Dashboard
        </h1>
        <p className="text-gray-600 mt-1">Welcome back! Here's your overview at a glance.</p>
      </motion.div>

      {/* Main Stats Cards - BLUISH THEME */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6"
      >
        <motion.div
          whileHover={{ scale: 1.02, y: -5 }}
          className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl shadow-lg border border-blue-400 p-6 text-white"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-white/20 rounded-lg backdrop-blur-sm">
              <Users className="w-6 h-6" />
            </div>
            <div className="text-right">
              <p className="text-sm font-medium opacity-90">Total Users</p>
              <p className="text-3xl font-bold">{stats?.totalUsers?.count || 0}</p>
            </div>
          </div>
          <div className="flex items-center gap-2 text-sm">
            <TrendingUp className="w-4 h-4" />
            <span>{stats?.totalUsers?.growth || '0%'} from last month</span>
          </div>
        </motion.div>

        <motion.div
          whileHover={{ scale: 1.02, y: -5 }}
          className="bg-gradient-to-br from-green-500 to-emerald-600 rounded-xl shadow-lg border border-green-400 p-6 text-white"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-white/20 rounded-lg backdrop-blur-sm">
              <FileText className="w-6 h-6" />
            </div>
            <div className="text-right">
              <p className="text-sm font-medium opacity-90">Total Posts</p>
              <p className="text-3xl font-bold">{stats?.totalPosts?.total || 0}</p>
            </div>
          </div>
          <div className="flex items-center gap-2 text-sm">
            <span className="font-medium">{stats?.totalPosts?.lost || 0} Lost</span>
            <span className="opacity-60">•</span>
            <span className="font-medium">{stats?.totalPosts?.found || 0} Found</span>
          </div>
        </motion.div>

        <motion.div
          whileHover={{ scale: 1.02, y: -5 }}
          className="bg-gradient-to-br from-purple-500 to-indigo-600 rounded-xl shadow-lg border border-purple-400 p-6 text-white"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-white/20 rounded-lg backdrop-blur-sm">
              <Award className="w-6 h-6" />
            </div>
            <div className="text-right">
              <p className="text-sm font-medium opacity-90">Total Claims</p>
              <p className="text-3xl font-bold">{stats?.claims?.total || 0}</p>
            </div>
          </div>
          <div className="flex items-center gap-2 text-sm">
            <span className="font-medium">{stats?.claims?.pending || 0} Pending</span>
          </div>
        </motion.div>

        <motion.div
          whileHover={{ scale: 1.02, y: -5 }}
          className="bg-gradient-to-br from-orange-500 to-amber-600 rounded-xl shadow-lg border border-orange-400 p-6 text-white"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-white/20 rounded-lg backdrop-blur-sm">
              <TrendingUp className="w-6 h-6" />
            </div>
            <div className="text-right">
              <p className="text-sm font-medium opacity-90">Total Revenue</p>
              <p className="text-3xl font-bold">Rs. {stats?.totalRevenue?.toLocaleString() || 0}</p>
            </div>
          </div>
          <div className="flex items-center gap-2 text-sm">
            <span className="font-medium">Rewards distributed</span>
          </div>
        </motion.div>
      </motion.div>

      {/* Claims Breakdown - BLUISH THEME */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3 }}
        className="bg-white rounded-xl shadow-lg border border-blue-100 p-6"
      >
        <h3 className="text-lg font-semibold text-gray-900 mb-6 flex items-center gap-2">
          <Award className="w-5 h-5 text-blue-600" />
          Claims Overview
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <motion.div
            whileHover={{ scale: 1.05 }}
            className="text-center p-6 bg-gradient-to-br from-amber-50 to-yellow-100 rounded-xl border-2 border-amber-200 shadow-sm"
          >
            <Clock className="w-10 h-10 text-amber-600 mx-auto mb-3" />
            <p className="text-4xl font-bold text-amber-700">
              {stats?.claims?.pending || 0}
            </p>
            <p className="text-sm font-semibold text-amber-600 mt-2">Pending Review</p>
          </motion.div>
          
          <motion.div
            whileHover={{ scale: 1.05 }}
            className="text-center p-6 bg-gradient-to-br from-green-50 to-emerald-100 rounded-xl border-2 border-green-200 shadow-sm"
          >
            <CheckCircle className="w-10 h-10 text-green-600 mx-auto mb-3" />
            <p className="text-4xl font-bold text-green-700">
              {stats?.claims?.accepted || 0}
            </p>
            <p className="text-sm font-semibold text-green-600 mt-2">Accepted</p>
          </motion.div>
          
          <motion.div
            whileHover={{ scale: 1.05 }}
            className="text-center p-6 bg-gradient-to-br from-red-50 to-rose-100 rounded-xl border-2 border-red-200 shadow-sm"
          >
            <XCircle className="w-10 h-10 text-red-600 mx-auto mb-3" />
            <p className="text-4xl font-bold text-red-700">
              {stats?.claims?.rejected || 0}
            </p>
            <p className="text-sm font-semibold text-red-600 mt-2">Rejected</p>
          </motion.div>
        </div>
      </motion.div>

      {/* Charts Row 1 - BLUISH THEME */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="grid grid-cols-1 lg:grid-cols-2 gap-6"
      >
        <div className="bg-white rounded-xl shadow-lg border border-blue-100 p-6">
          <Chart
            type="line"
            title="User Registrations (Last 30 Days)"
            data={charts?.userRegistrations || []}
            xKey="date"
            yKey="users"
            color="#3b82f6"
            loading={chartsLoading}
          />
        </div>
        <div className="bg-white rounded-xl shadow-lg border border-blue-100 p-6">
          <Chart
            type="bar"
            title="Posts Activity (Last 30 Days)"
            data={charts?.postsPerDay || []}
            xKey="date"
            yKey="posts"
            color="#10b981"
            loading={chartsLoading}
          />
        </div>
      </motion.div>

      {/* Charts Row 2 - BLUISH THEME */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="grid grid-cols-1 lg:grid-cols-2 gap-6"
      >
        <div className="bg-white rounded-xl shadow-lg border border-blue-100 p-6">
          <Chart
            type="donut"
            title="Post Types Distribution"
            data={charts?.postDistribution || []}
            xKey="type"
            yKey="count"
            colors={['#10b981', '#3b82f6']}
            loading={chartsLoading}
          />
        </div>
        <div className="bg-white rounded-xl shadow-lg border border-blue-100 p-6">
          <Chart
            type="pie"
            title="Claim Status Distribution"
            data={charts?.claimDistribution || []}
            xKey="status"
            yKey="count"
            colors={['#eab308', '#10b981', '#ef4444']}
            loading={chartsLoading}
          />
        </div>
      </motion.div>

      {/* Recent Activity - FULLY FIXED */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
        className="bg-white rounded-xl shadow-lg border border-blue-100 p-6"
      >
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
            <Clock className="w-5 h-5 text-blue-600" />
            Recent Activity
          </h3>
          <span className="text-sm text-blue-600 font-medium">Last 24 hours</span>
        </div>
        
        {activityLoading ? (
          <div className="space-y-4">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="flex items-start gap-4 animate-pulse">
                <div className="w-12 h-12 bg-blue-100 rounded-full"></div>
                <div className="flex-1 space-y-2">
                  <div className="h-4 bg-blue-100 rounded w-3/4"></div>
                  <div className="h-3 bg-blue-50 rounded w-1/2"></div>
                </div>
              </div>
            ))}
          </div>
        ) : activityFeed && activityFeed.length > 0 ? (
          <div className="space-y-3">
            {activityFeed.map((item, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.05 }}
                whileHover={{ scale: 1.01, backgroundColor: '#eff6ff' }}
                className="flex items-start gap-4 p-4 rounded-xl transition-all cursor-pointer border border-blue-50 hover:border-blue-200 hover:shadow-md"
              >
                <img
                  src={item.avatar}
                  alt="Avatar"
                  className="w-12 h-12 rounded-full border-2 border-blue-200 shadow-sm"
                />
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1">
                      <p className="text-sm font-semibold text-gray-900">{item.title}</p>
                      <p className="text-sm text-gray-600 mt-1 line-clamp-2">{item.description}</p>
                    </div>
                    <div className={`p-2 rounded-lg ${
                      item.type === 'user' ? 'bg-blue-100' : 'bg-green-100'
                    }`}>
                      <item.icon className={`w-4 h-4 ${
                        item.type === 'user' ? 'text-blue-600' : 'text-green-600'
                      }`} />
                    </div>
                  </div>
                  <p className="text-xs text-gray-400 mt-2 flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {item.timestamp}
                  </p>
                </div>
              </motion.div>
            ))}
          </div>
        ) : (
          <div className="text-center py-12">
            <div className="w-16 h-16 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-4">
              <Clock className="w-8 h-8 text-blue-400" />
            </div>
            <p className="text-gray-500 font-medium">No recent activity</p>
            <p className="text-sm text-gray-400 mt-1">Activity will appear here as it happens</p>
          </div>
        )}
      </motion.div>
    </motion.div>
  );
};

export default Dashboard;