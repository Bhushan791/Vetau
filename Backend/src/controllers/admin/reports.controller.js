import { User } from "../../models/user.model.js";
import { Post } from "../../models/post.model.js";
import { Claim } from "../../models/claim.model.js";
import { Comment } from "../../models/comment.model.js";
import { Message } from "../../models/message.model.js";
import { ApiError } from "../../utils/apiError.js";
import { ApiResponse } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

// ============================================
// A. USER ANALYTICS
// ============================================
export const getUserAnalytics = asyncHandler(async (req, res) => {
  const { period = "30" } = req.query;

  const daysAgo = parseInt(period);
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - daysAgo);

  const totalUsers = await User.countDocuments({ isDeleted: false });

  const newUsers = await User.countDocuments({
    isDeleted: false,
    createdAt: { $gte: startDate },
  });

  const previousPeriodStart = new Date(startDate);
  previousPeriodStart.setDate(previousPeriodStart.getDate() - daysAgo);
  const previousNewUsers = await User.countDocuments({
    isDeleted: false,
    createdAt: { $gte: previousPeriodStart, $lt: startDate },
  });

  const growthRate =
    previousNewUsers > 0
      ? (((newUsers - previousNewUsers) / previousNewUsers) * 100).toFixed(2)
      : 100;

  const authDistribution = await User.aggregate([
    { $match: { isDeleted: false } },
    {
      $group: {
        _id: "$authType",
        count: { $sum: 1 },
      },
    },
  ]);

  const statusDistribution = await User.aggregate([
    { $match: { isDeleted: false } },
    {
      $group: {
        _id: "$status",
        count: { $sum: 1 },
      },
    },
  ]);

  const registrationTrend = await User.aggregate([
    {
      $match: {
        isDeleted: false,
        createdAt: { $gte: startDate },
      },
    },
    {
      $group: {
        _id: {
          $dateToString: { format: "%Y-%m-%d", date: "$createdAt" },
        },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  const topContributors = await Post.aggregate([
    { $match: { isDeleted: false } },
    {
      $group: {
        _id: "$userId",
        totalPosts: { $sum: 1 },
      },
    },
    {
      $lookup: {
        from: "users",
        localField: "_id",
        foreignField: "_id",
        as: "user",
      },
    },
    { $unwind: "$user" },
    {
      $project: {
        userId: "$user.userId",
        fullName: "$user.fullName",
        username: "$user.username",
        email: "$user.email",
        profileImage: "$user.profileImage",
        totalPosts: 1,
      },
    },
    { $sort: { totalPosts: -1 } },
    { $limit: 10 },
  ]);

  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  const activeUsers = await User.countDocuments({
    isDeleted: false,
    lastActive: { $gte: sevenDaysAgo },
  });
  const retentionRate =
    totalUsers > 0 ? ((activeUsers / totalUsers) * 100).toFixed(2) : 0;

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        totalUsers,
        newUsers,
        growthRate: `${growthRate}%`,
        authDistribution,
        statusDistribution,
        registrationTrend,
        topContributors,
        retentionRate: `${retentionRate}%`,
        activeUsersLast7Days: activeUsers,
      },
      "User analytics fetched successfully"
    )
  );
});

// ============================================
// B. POST ANALYTICS
// ============================================
export const getPostAnalytics = asyncHandler(async (req, res) => {
  const { period = "30" } = req.query;

  const daysAgo = parseInt(period);
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - daysAgo);

  const totalPosts = await Post.countDocuments({ isDeleted: false });

  const newPosts = await Post.countDocuments({
    isDeleted: false,
    createdAt: { $gte: startDate },
  });

  const typeDistribution = await Post.aggregate([
    { $match: { isDeleted: false } },
    {
      $group: {
        _id: "$type",
        count: { $sum: 1 },
      },
    },
  ]);

  const statusDistribution = await Post.aggregate([
    { $match: { isDeleted: false } },
    {
      $group: {
        _id: "$status",
        count: { $sum: 1 },
      },
    },
  ]);

  const categoryDistribution = await Post.aggregate([
    { $match: { isDeleted: false } },
    {
      $group: {
        _id: "$category",
        count: { $sum: 1 },
      },
    },
    { $sort: { count: -1 } },
    { $limit: 10 },
  ]);

  const postsTrend = await Post.aggregate([
    {
      $match: {
        isDeleted: false,
        createdAt: { $gte: startDate },
      },
    },
    {
      $group: {
        _id: {
          $dateToString: { format: "%Y-%m-%d", date: "$createdAt" },
        },
        total: { $sum: 1 },
        lost: {
          $sum: { $cond: [{ $eq: ["$type", "lost"] }, 1, 0] },
        },
        found: {
          $sum: { $cond: [{ $eq: ["$type", "found"] }, 1, 0] },
        },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  const avgReward = await Post.aggregate([
    {
      $match: {
        isDeleted: false,
        type: "lost",
        rewardAmount: { $gt: 0 },
      },
    },
    {
      $group: {
        _id: null,
        avgReward: { $avg: "$rewardAmount" },
      },
    },
  ]);

  const returnedPosts = await Post.countDocuments({
    isDeleted: false,
    status: "returned",
  });
  const successRate =
    totalPosts > 0 ? ((returnedPosts / totalPosts) * 100).toFixed(2) : 0;

  const mostCommentedPosts = await Comment.aggregate([
    {
      $group: {
        _id: "$postId",
        commentCount: { $sum: 1 },
      },
    },
    {
      $lookup: {
        from: "posts",
        localField: "_id",
        foreignField: "_id",
        as: "post",
      },
    },
    { $unwind: "$post" },
    { $match: { "post.isDeleted": false } },
    {
      $project: {
        postId: "$post.postId",
        itemName: "$post.itemName",
        type: "$post.type",
        category: "$post.category",
        commentCount: 1,
      },
    },
    { $sort: { commentCount: -1 } },
    { $limit: 10 },
  ]);

  const mostClaimedPosts = await Claim.aggregate([
    {
      $group: {
        _id: "$postId",
        claimCount: { $sum: 1 },
      },
    },
    {
      $lookup: {
        from: "posts",
        localField: "_id",
        foreignField: "_id",
        as: "post",
      },
    },
    { $unwind: "$post" },
    { $match: { "post.isDeleted": false } },
    {
      $project: {
        postId: "$post.postId",
        itemName: "$post.itemName",
        type: "$post.type",
        category: "$post.category",
        claimCount: 1,
      },
    },
    { $sort: { claimCount: -1 } },
    { $limit: 10 },
  ]);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        totalPosts,
        newPosts,
        typeDistribution,
        statusDistribution,
        categoryDistribution,
        postsTrend,
        avgReward: avgReward[0]?.avgReward
          ? `Rs. ${avgReward[0].avgReward.toFixed(2)}`
          : "N/A",
        successRate: `${successRate}%`,
        returnedPosts,
        mostCommentedPosts,
        mostClaimedPosts,
      },
      "Post analytics fetched successfully"
    )
  );
});

// ============================================
// C. REVENUE ANALYTICS - FIXED WITH Rs.
// ============================================
export const getRevenueAnalytics = asyncHandler(async (req, res) => {
  const { period = "30" } = req.query;

  const daysAgo = parseInt(period);
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - daysAgo);

  // Total Revenue
  const totalRevenue = await Post.aggregate([
    {
      $match: {
        isDeleted: false,
        type: "lost",
        rewardAmount: { $gt: 0 },
      },
    },
    {
      $group: {
        _id: null,
        total: { $sum: "$rewardAmount" },
      },
    },
  ]);

  // Revenue in Period
  const periodRevenue = await Post.aggregate([
    {
      $match: {
        isDeleted: false,
        type: "lost",
        rewardAmount: { $gt: 0 },
        createdAt: { $gte: startDate },
      },
    },
    {
      $group: {
        _id: null,
        total: { $sum: "$rewardAmount" },
      },
    },
  ]);

  // Revenue Trend (Daily)
  const revenueTrend = await Post.aggregate([
    {
      $match: {
        isDeleted: false,
        type: "lost",
        rewardAmount: { $gt: 0 },
        createdAt: { $gte: startDate },
      },
    },
    {
      $group: {
        _id: {
          $dateToString: { format: "%Y-%m-%d", date: "$createdAt" },
        },
        totalRevenue: { $sum: "$rewardAmount" },
        postCount: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  // Reward Distribution by Range
  const rewardDistribution = await Post.aggregate([
    {
      $match: {
        isDeleted: false,
        type: "lost",
        rewardAmount: { $gt: 0 },
      },
    },
    {
      $bucket: {
        groupBy: "$rewardAmount",
        boundaries: [0, 500, 1000, 2000, 5000, 10000, 50000],
        default: "50000+",
        output: {
          count: { $sum: 1 },
          totalAmount: { $sum: "$rewardAmount" },
        },
      },
    },
  ]);

  // Average Reward by Category
  const avgRewardByCategory = await Post.aggregate([
    {
      $match: {
        isDeleted: false,
        type: "lost",
        rewardAmount: { $gt: 0 },
      },
    },
    {
      $group: {
        _id: "$category",
        avgReward: { $avg: "$rewardAmount" },
        totalPosts: { $sum: 1 },
        totalRevenue: { $sum: "$rewardAmount" },
      },
    },
    { $sort: { avgReward: -1 } },
  ]);

  // High-Value Posts (≥Rs. 5000)
  const highValuePosts = await Post.countDocuments({
    isDeleted: false,
    type: "lost",
    rewardAmount: { $gte: 5000 },
  });

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        totalRevenue: totalRevenue[0]?.total
          ? `Rs. ${totalRevenue[0].total.toLocaleString("en-IN")}`
          : "Rs. 0",
        periodRevenue: periodRevenue[0]?.total
          ? `Rs. ${periodRevenue[0].total.toLocaleString("en-IN")}`
          : "Rs. 0",
        revenueTrend,
        rewardDistribution,
        avgRewardByCategory,
        highValuePosts,
      },
      "Revenue analytics fetched successfully"
    )
  );
});

// ============================================
// D. ENGAGEMENT ANALYTICS
// ============================================
export const getEngagementAnalytics = asyncHandler(async (req, res) => {
  const { period = "30" } = req.query;

  const daysAgo = parseInt(period);
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - daysAgo);

  const totalComments = await Comment.countDocuments();

  const periodComments = await Comment.countDocuments({
    createdAt: { $gte: startDate },
  });

  let totalMessages = 0;
  let periodMessages = 0;
  try {
    totalMessages = await Message.countDocuments();
    periodMessages = await Message.countDocuments({
      createdAt: { $gte: startDate },
    });
  } catch (error) {
    console.log("Message model not available");
  }

  const commentTrend = await Comment.aggregate([
    {
      $match: {
        createdAt: { $gte: startDate },
      },
    },
    {
      $group: {
        _id: {
          $dateToString: { format: "%Y-%m-%d", date: "$createdAt" },
        },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  const topCommenters = await Comment.aggregate([
    {
      $group: {
        _id: "$userId",
        commentCount: { $sum: 1 },
      },
    },
    {
      $lookup: {
        from: "users",
        localField: "_id",
        foreignField: "_id",
        as: "user",
      },
    },
    { $unwind: "$user" },
    { $match: { "user.isDeleted": false } },
    {
      $project: {
        userId: "$user.userId",
        fullName: "$user.fullName",
        username: "$user.username",
        email: "$user.email",
        profileImage: "$user.profileImage",
        commentCount: 1,
      },
    },
    { $sort: { commentCount: -1 } },
    { $limit: 10 },
  ]);

  const avgCommentsPerPost = await Comment.aggregate([
    {
      $group: {
        _id: "$postId",
        commentCount: { $sum: 1 },
      },
    },
    {
      $group: {
        _id: null,
        avgComments: { $avg: "$commentCount" },
      },
    },
  ]);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        totalComments,
        periodComments,
        totalMessages,
        periodMessages,
        commentTrend,
        topCommenters,
        avgCommentsPerPost: avgCommentsPerPost[0]?.avgComments
          ? avgCommentsPerPost[0].avgComments.toFixed(2)
          : "0",
      },
      "Engagement analytics fetched successfully"
    )
  );
});