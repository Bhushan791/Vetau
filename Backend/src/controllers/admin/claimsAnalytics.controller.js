import { Claim } from "../../models/claim.model.js";
import { Post } from "../../models/post.model.js";
import { User } from "../../models/user.model.js";
import { ApiError } from "../../utils/apiError.js";
import { ApiResponse } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

// ============================================
// GET CLAIMS ANALYTICS OVERVIEW
// ============================================
export const getClaimsAnalytics = asyncHandler(async (req, res) => {
  // Total Claims
  const totalClaims = await Claim.countDocuments();

  // Claims by Status
  const claimsByStatus = await Claim.aggregate([
    {
      $group: {
        _id: "$status",
        count: { $sum: 1 },
      },
    },
  ]);

  const statusBreakdown = {
    pending: 0,
    accepted: 0,
    rejected: 0,
  };

  claimsByStatus.forEach((item) => {
    statusBreakdown[item._id] = item.count;
  });

  // Calculate Success Rate
  const successRate =
    totalClaims > 0
      ? ((statusBreakdown.accepted / totalClaims) * 100).toFixed(2)
      : 0;

  // Lost Claims (claims on FOUND posts)
  const lostClaims = await Claim.aggregate([
    {
      $lookup: {
        from: "posts",
        localField: "postId",
        foreignField: "_id",
        as: "post",
      },
    },
    { $unwind: "$post" },
    { $match: { "post.type": "found" } },
    { $count: "count" },
  ]);

  // Found Claims (claims on LOST posts)
  const foundClaims = await Claim.aggregate([
    {
      $lookup: {
        from: "posts",
        localField: "postId",
        foreignField: "_id",
        as: "post",
      },
    },
    { $unwind: "$post" },
    { $match: { "post.type": "lost" } },
    { $count: "count" },
  ]);

  // Average Time to Accept/Reject (in hours)
  const avgTimeToResponse = await Claim.aggregate([
    {
      $match: {
        status: { $in: ["accepted", "rejected"] },
        updatedAt: { $exists: true },
      },
    },
    {
      $project: {
        responseTime: {
          $divide: [
            { $subtract: ["$updatedAt", "$createdAt"] },
            1000 * 60 * 60, // Convert to hours
          ],
        },
      },
    },
    {
      $group: {
        _id: null,
        avgHours: { $avg: "$responseTime" },
      },
    },
  ]);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        totalClaims,
        lostClaims: lostClaims[0]?.count || 0,
        foundClaims: foundClaims[0]?.count || 0,
        statusBreakdown,
        successRate: `${successRate}%`,
        avgResponseTime: avgTimeToResponse[0]
          ? `${avgTimeToResponse[0].avgHours.toFixed(1)} hours`
          : "N/A",
      },
      "Claims analytics fetched successfully"
    )
  );
});

// ============================================
// GET CLAIMS TREND (Daily/Weekly/Monthly)
// ============================================
export const getClaimsTrend = asyncHandler(async (req, res) => {
  const { period = "30" } = req.query; // days: 7, 30, 90

  const daysAgo = parseInt(period);
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - daysAgo);

  // Claims per day
  const claimsTrend = await Claim.aggregate([
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
        total: { $sum: 1 },
        accepted: {
          $sum: { $cond: [{ $eq: ["$status", "accepted"] }, 1, 0] },
        },
        rejected: {
          $sum: { $cond: [{ $eq: ["$status", "rejected"] }, 1, 0] },
        },
        pending: {
          $sum: { $cond: [{ $eq: ["$status", "pending"] }, 1, 0] },
        },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  // Acceptance Rate Over Time
  const acceptanceRateTrend = claimsTrend.map((day) => ({
    date: day._id,
    acceptanceRate:
      day.total > 0 ? ((day.accepted / day.total) * 100).toFixed(2) : 0,
  }));

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        claimsTrend,
        acceptanceRateTrend,
        period: `${daysAgo} days`,
      },
      "Claims trend fetched successfully"
    )
  );
});

// ============================================
// GET TOP CLAIMERS (Leaderboard)
// ============================================
export const getTopClaimers = asyncHandler(async (req, res) => {
  const { limit = 10 } = req.query;

  const topClaimers = await Claim.aggregate([
    {
      $group: {
        _id: "$claimerId",
        totalClaims: { $sum: 1 },
        acceptedClaims: {
          $sum: { $cond: [{ $eq: ["$status", "accepted"] }, 1, 0] },
        },
        rejectedClaims: {
          $sum: { $cond: [{ $eq: ["$status", "rejected"] }, 1, 0] },
        },
        pendingClaims: {
          $sum: { $cond: [{ $eq: ["$status", "pending"] }, 1, 0] },
        },
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
        totalClaims: 1,
        acceptedClaims: 1,
        rejectedClaims: 1,
        pendingClaims: 1,
        successRate: {
          $cond: [
            { $eq: ["$totalClaims", 0] },
            0,
            {
              $multiply: [
                { $divide: ["$acceptedClaims", "$totalClaims"] },
                100,
              ],
            },
          ],
        },
      },
    },
    { $sort: { totalClaims: -1 } },
    { $limit: parseInt(limit) },
  ]);

  return res.status(200).json(
    new ApiResponse(
      200,
      topClaimers,
      "Top claimers fetched successfully"
    )
  );
});

// ============================================
// GET CLAIMS BY POST TYPE (Lost vs Found)
// ============================================
export const getClaimsByPostType = asyncHandler(async (req, res) => {
  const claimsByType = await Claim.aggregate([
    {
      $lookup: {
        from: "posts",
        localField: "postId",
        foreignField: "_id",
        as: "post",
      },
    },
    { $unwind: "$post" },
    {
      $group: {
        _id: "$post.type",
        totalClaims: { $sum: 1 },
        accepted: {
          $sum: { $cond: [{ $eq: ["$status", "accepted"] }, 1, 0] },
        },
        rejected: {
          $sum: { $cond: [{ $eq: ["$status", "rejected"] }, 1, 0] },
        },
        pending: {
          $sum: { $cond: [{ $eq: ["$status", "pending"] }, 1, 0] },
        },
      },
    },
  ]);

  const breakdown = {
    lost: { totalClaims: 0, accepted: 0, rejected: 0, pending: 0 },
    found: { totalClaims: 0, accepted: 0, rejected: 0, pending: 0 },
  };

  claimsByType.forEach((item) => {
    breakdown[item._id] = {
      totalClaims: item.totalClaims,
      accepted: item.accepted,
      rejected: item.rejected,
      pending: item.pending,
    };
  });

  return res.status(200).json(
    new ApiResponse(
      200,
      breakdown,
      "Claims by post type fetched successfully"
    )
  );
});

// ============================================
// GET RECENT CLAIMS ACTIVITY
// ============================================
export const getRecentClaimsActivity = asyncHandler(async (req, res) => {
  const { limit = 10 } = req.query;

  const recentClaims = await Claim.find()
    .populate("claimerId", "fullName username email profileImage")
    .populate("postId", "postId itemName type category")
    .sort({ createdAt: -1 })
    .limit(parseInt(limit));

  return res.status(200).json(
    new ApiResponse(
      200,
      recentClaims,
      "Recent claims activity fetched successfully"
    )
  );
});