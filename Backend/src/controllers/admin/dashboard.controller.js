import { User } from "../../models/user.model.js";
import { Post } from "../../models/post.model.js";
import { Claim } from "../../models/claim.model.js";
import { ApiError } from "../../utils/apiError.js";
import { ApiResponse } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

// ============================================
// GET DASHBOARD STATS (Metric Cards)
// ============================================
const getDashboardStats = asyncHandler(async (req, res) => {
  // Total Users (excluding soft-deleted)
  const totalUsers = await User.countDocuments({ isDeleted: false });
  
  // Total Users last month (for growth calculation)
  const lastMonthDate = new Date();
  lastMonthDate.setMonth(lastMonthDate.getMonth() - 1);
  
  const usersLastMonth = await User.countDocuments({
    isDeleted: false,
    createdAt: { $lt: lastMonthDate }
  });
  
  const userGrowth = usersLastMonth > 0 
    ? (((totalUsers - usersLastMonth) / usersLastMonth) * 100).toFixed(1)
    : 0;

  // Total Posts (excluding soft-deleted)
  const totalPosts = await Post.countDocuments({ isDeleted: false });
  const lostPosts = await Post.countDocuments({ isDeleted: false, type: "lost" });
  const foundPosts = await Post.countDocuments({ isDeleted: false, type: "found" });

  // Active Claims (pending + accepted, rejected excluded)
  const pendingClaims = await Claim.countDocuments({ status: "pending" });
  const acceptedClaims = await Claim.countDocuments({ status: "accepted" });
  const rejectedClaims = await Claim.countDocuments({ status: "rejected" });

  // Total Revenue (sum of all reward amounts from posts)
  const revenueData = await Post.aggregate([
    { $match: { isDeleted: false } },
    { $group: { _id: null, total: { $sum: "$rewardAmount" } } }
  ]);
  const totalRevenue = revenueData.length > 0 ? revenueData[0].total : 0;

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        totalUsers: {
          count: totalUsers,
          growth: `${userGrowth}%`
        },
        totalPosts: {
          total: totalPosts,
          lost: lostPosts,
          found: foundPosts
        },
        claims: {
          pending: pendingClaims,
          accepted: acceptedClaims,
          rejected: rejectedClaims,
          total: pendingClaims + acceptedClaims + rejectedClaims
        },
        totalRevenue: totalRevenue
      },
      "Dashboard stats fetched successfully"
    )
  );
});

// ============================================
// GET DASHBOARD CHARTS
// ============================================
const getDashboardCharts = asyncHandler(async (req, res) => {
  const { days = 30 } = req.query; // Default: last 30 days
  
  const daysAgo = new Date();
  daysAgo.setDate(daysAgo.getDate() - parseInt(days));

  // ===== CHART 1: User Registrations Over Time (Line Chart) =====
  const userRegistrations = await User.aggregate([
    { 
      $match: { 
        isDeleted: false,
        createdAt: { $gte: daysAgo } 
      } 
    },
    {
      $group: {
        _id: { 
          $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } 
        },
        count: { $sum: 1 }
      }
    },
    { $sort: { _id: 1 } }
  ]);

  // ===== CHART 2: Posts Created Per Day (Bar Chart) =====
  const postsPerDay = await Post.aggregate([
    { 
      $match: { 
        isDeleted: false,
        createdAt: { $gte: daysAgo } 
      } 
    },
    {
      $group: {
        _id: { 
          $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } 
        },
        count: { $sum: 1 }
      }
    },
    { $sort: { _id: 1 } }
  ]);

  // ===== CHART 3: Post Distribution (Pie Chart - Lost vs Found) =====
  const postDistribution = await Post.aggregate([
    { $match: { isDeleted: false } },
    {
      $group: {
        _id: "$type",
        count: { $sum: 1 }
      }
    }
  ]);

  // ===== CHART 4: Claim Status Distribution (Donut Chart) =====
  const claimDistribution = await Claim.aggregate([
    {
      $group: {
        _id: "$status",
        count: { $sum: 1 }
      }
    }
  ]);

  // ===== CHART 5: Revenue Trend (Area Chart) =====
  const revenueTrend = await Post.aggregate([
    { 
      $match: { 
        isDeleted: false,
        createdAt: { $gte: daysAgo } 
      } 
    },
    {
      $group: {
        _id: { 
          $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } 
        },
        totalRevenue: { $sum: "$rewardAmount" }
      }
    },
    { $sort: { _id: 1 } }
  ]);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        userRegistrations: userRegistrations.map(item => ({
          date: item._id,
          users: item.count
        })),
        postsPerDay: postsPerDay.map(item => ({
          date: item._id,
          posts: item.count
        })),
        postDistribution: postDistribution.map(item => ({
          type: item._id,
          count: item.count
        })),
        claimDistribution: claimDistribution.map(item => ({
          status: item._id,
          count: item.count
        })),
        revenueTrend: revenueTrend.map(item => ({
          date: item._id,
          revenue: item.totalRevenue
        }))
      },
      "Dashboard charts fetched successfully"
    )
  );
});

// ============================================
// GET RECENT ACTIVITY (Activity Feed)
// ============================================
const getRecentActivity = asyncHandler(async (req, res) => {
  // Latest 10 users registered
  const recentUsers = await User.find({ isDeleted: false })
    .select("userId fullName username email profileImage createdAt")
    .sort({ createdAt: -1 })
    .limit(10);

  // Latest 10 posts created
  const recentPosts = await Post.find({ isDeleted: false })
    .populate("userId", "fullName username email profileImage")
    .select("postId itemName type category images createdAt")
    .sort({ createdAt: -1 })
    .limit(10);

  // Latest 10 claims made
  const recentClaims = await Claim.find()
    .populate("claimerId", "fullName username email profileImage")
    .populate("postId", "postId itemName type")
    .select("claimId claimType status createdAt")
    .sort({ createdAt: -1 })
    .limit(10);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        recentUsers,
        recentPosts,
        recentClaims
      },
      "Recent activity fetched successfully"
    )
  );
});

// ============================================
// EXPORTS
// ============================================
export {
  getDashboardStats,
  getDashboardCharts,
  getRecentActivity
};