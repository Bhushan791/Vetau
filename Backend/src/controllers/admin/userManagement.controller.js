import { User } from "../../models/user.model.js";
import { Post } from "../../models/post.model.js";
import { Claim } from "../../models/claim.model.js";
import { Comment } from "../../models/comment.model.js";
import { ApiError } from "../../utils/apiError.js";
import { ApiResponse } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

// ============================================
// GET ALL USERS (ADMIN VIEW - includes banned/deleted)
// ============================================
const getAllUsers = asyncHandler(async (req, res) => {
  // Gets all users with search, filters, and pagination. Shows banned/deleted users too.
  const {
    search,
    authType,
    status,
    role,
    includeDeleted = "false",
    startDate,
    endDate,
    page = 1,
    limit = 10,
  } = req.query;

  const filter = {};

  // Show deleted users only if requested
  if (includeDeleted === "true") {
    // Show all (including deleted)
  } else {
    filter.isDeleted = false;
  }

  if (authType) filter.authType = authType;
  if (status) filter.status = status;
  if (role) filter.role = role;

  // Date range
  if (startDate || endDate) {
    filter.createdAt = {};
    if (startDate) filter.createdAt.$gte = new Date(startDate);
    if (endDate) filter.createdAt.$lte = new Date(endDate);
  }

  // Search by name, email, username
  if (search) {
    filter.$or = [
      { fullName: { $regex: search, $options: "i" } },
      { email: { $regex: search, $options: "i" } },
      { username: { $regex: search, $options: "i" } },
    ];
  }

  const skip = (parseInt(page) - 1) * parseInt(limit);

  const users = await User.find(filter)
    .select("-password -refreshToken")
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

  const totalUsers = await User.countDocuments(filter);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        users,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalUsers / parseInt(limit)),
          totalUsers,
          hasMore: skip + users.length < totalUsers,
        },
      },
      "Users fetched successfully"
    )
  );
});

// ============================================
// GET USER DETAILS (ADMIN VIEW)
// ============================================
const getUserDetails = asyncHandler(async (req, res) => {
  // Gets single user with full profile + activity stats (posts, claims, comments count, last active).
  const { userId } = req.params;

  const user = await User.findOne({ userId }).select("-password -refreshToken");

  if (!user) {
    throw new ApiError(404, "User not found");
  }

  // Get user's activity stats
  const totalPosts = await Post.countDocuments({
    userId: user._id,
    isDeleted: false,
  });

  const totalClaims = await Claim.countDocuments({
    claimerId: user._id,
  });

  const totalComments = await Comment.countDocuments({
    userId: user._id,
  });

  // Calculate account age in days
  const accountAgeDays = Math.floor(
    (Date.now() - user.createdAt) / (1000 * 60 * 60 * 24)
  );

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        user,
        stats: {
          totalPosts,
          totalClaims,
          totalComments,
          accountAgeDays,
          lastActive: user.lastActive,
        },
      },
      "User details fetched successfully"
    )
  );
});

// ============================================
// BAN USER
// ============================================
const banUser = asyncHandler(async (req, res) => {
  // Sets user status to "banned". User cannot login anymore.
  const { userId } = req.params;
  const { reason } = req.body; // Optional ban reason

  const user = await User.findOne({ userId, isDeleted: false });

  if (!user) {
    throw new ApiError(404, "User not found");
  }

  if (user.role === "admin") {
    throw new ApiError(403, "Cannot ban an admin user");
  }

  if (user.status === "banned") {
    throw new ApiError(400, "User is already banned");
  }

  user.status = "banned";
  user.banReason = reason || "Banned by admin";
  user.bannedAt = new Date();
  await user.save();

  return res.status(200).json(
    new ApiResponse(200, user, "User banned successfully")
  );
});

// ============================================
// UNBAN USER
// ============================================
const unbanUser = asyncHandler(async (req, res) => {
  // Sets user status back to "active". User can login again.
  const { userId } = req.params;

  const user = await User.findOne({ userId, isDeleted: false });

  if (!user) {
    throw new ApiError(404, "User not found");
  }

  if (user.status !== "banned") {
    throw new ApiError(400, "User is not banned");
  }

  user.status = "active";
  user.banReason = undefined;
  user.bannedAt = undefined;
  await user.save();

  return res.status(200).json(
    new ApiResponse(200, user, "User unbanned successfully")
  );
});

// ============================================
// SOFT DELETE USER
// ============================================
const softDeleteUser = asyncHandler(async (req, res) => {
  // Marks user as deleted (sets isDeleted: true). User cannot login and is hidden from lists.
  const { userId } = req.params;

  const user = await User.findOne({ userId });

  if (!user) {
    throw new ApiError(404, "User not found");
  }

  if (user.role === "admin") {
    throw new ApiError(403, "Cannot delete an admin user");
  }

  if (user.isDeleted) {
    throw new ApiError(400, "User is already deleted");
  }

  user.isDeleted = true;
  user.deletedAt = new Date();
  await user.save();

  return res.status(200).json(
    new ApiResponse(200, user, "User deleted successfully")
  );
});

// ============================================
// RESTORE USER
// ============================================
const restoreUser = asyncHandler(async (req, res) => {
  // Un-deletes a soft-deleted user. User becomes active again.
  const { userId } = req.params;

  const user = await User.findOne({ userId });

  if (!user) {
    throw new ApiError(404, "User not found");
  }

  if (!user.isDeleted) {
    throw new ApiError(400, "User is not deleted");
  }

  user.isDeleted = false;
  user.deletedAt = null;
  await user.save();

  return res.status(200).json(
    new ApiResponse(200, user, "User restored successfully")
  );
});

// ============================================
// EXPORT USERS TO CSV
// ============================================
const exportUsers = asyncHandler(async (req, res) => {
  // Returns all users in CSV-friendly format for frontend to download.
  const { includeDeleted = "false" } = req.query;

  const filter = includeDeleted === "true" ? {} : { isDeleted: false };

  const users = await User.find(filter)
    .select("userId fullName username email authType status role createdAt lastActive")
    .sort({ createdAt: -1 });

  const csvData = users.map((user) => ({
    userId: user.userId,
    fullName: user.fullName,
    username: user.username || "N/A",
    email: user.email,
    authType: user.authType,
    status: user.status,
    role: user.role,
    joinedDate: user.createdAt,
    lastActive: user.lastActive || "N/A",
    isDeleted: user.isDeleted,
  }));

  return res.status(200).json(
    new ApiResponse(200, csvData, "Users exported successfully")
  );
});

// ============================================
// EXPORTS
// ============================================
export {
  getAllUsers,
  getUserDetails,
  banUser,
  unbanUser,
  softDeleteUser,
  restoreUser,
  exportUsers,
};