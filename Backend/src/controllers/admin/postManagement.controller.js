import { Post } from "../../models/post.model.js";
import { User } from "../../models/user.model.js";
import { Claim } from "../../models/claim.model.js";
import { Comment } from "../../models/comment.model.js";
import { ApiError } from "../../utils/apiError.js";
import { ApiResponse } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

// ============================================
// GET ALL POSTS (ADMIN VIEW - includes deleted)
// ============================================
const getAllPostsAdmin = asyncHandler(async (req, res) => {
  const {
    search,
    type,
    category,
    status,
    isAnonymous,
    rewardMin,
    rewardMax,
    startDate,
    endDate,
    includeDeleted = "false", // Show deleted posts?
    page = 1,
    limit = 10,
  } = req.query;

  // Build filter
  const filter = {};

  // Show deleted posts only if requested
  if (includeDeleted === "true") {
    // Show all posts (including deleted)
  } else {
    filter.isDeleted = false; // Hide deleted by default
  }

  if (type) filter.type = type;
  if (category) filter.category = category.toLowerCase();
  if (status) filter.status = status;
  if (isAnonymous) filter.isAnonymous = isAnonymous === "true";

  // Reward range filter
  if (rewardMin || rewardMax) {
    filter.rewardAmount = {};
    if (rewardMin) filter.rewardAmount.$gte = parseInt(rewardMin);
    if (rewardMax) filter.rewardAmount.$lte = parseInt(rewardMax);
  }

  // Date range filter
  if (startDate || endDate) {
    filter.createdAt = {};
    if (startDate) filter.createdAt.$gte = new Date(startDate);
    if (endDate) filter.createdAt.$lte = new Date(endDate);
  }

  // Search in item name, description, tags
  if (search) {
    filter.$or = [
      { itemName: { $regex: search, $options: "i" } },
      { description: { $regex: search, $options: "i" } },
      { tags: { $in: [new RegExp(search, "i")] } },
    ];
  }

  const skip = (parseInt(page) - 1) * parseInt(limit);

  const posts = await Post.find(filter)
    .populate("userId", "fullName username email profileImage")
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

  const totalPosts = await Post.countDocuments(filter);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        posts,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalPosts / parseInt(limit)),
          totalPosts,
          hasMore: skip + posts.length < totalPosts,
        },
      },
      "Posts fetched successfully"
    )
  );
});

// ============================================
// GET POST DETAILS (ADMIN VIEW)
// ============================================
const getPostDetailsAdmin = asyncHandler(async (req, res) => {
  // Fetches full post details including all claims and comments
  const { postId } = req.params;

  const post = await Post.findOne({ postId })
    .populate("userId", "fullName username email profileImage address");

  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  // Get all claims on this post
  const claims = await Claim.find({ postId: post._id })
    .populate("claimerId", "fullName username email profileImage")
    .sort({ createdAt: -1 });

  // Get all comments on this post
  const comments = await Comment.find({ postId: post._id })
    .populate("userId", "fullName username profileImage")
    .sort({ createdAt: -1 });

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        post,
        claims,
        comments,
        stats: {
          totalClaims: claims.length,
          totalComments: comments.length,
        },
      },
      "Post details fetched successfully"
    )
  );
});

// ============================================
// SOFT DELETE POST
// ============================================
const softDeletePost = asyncHandler(async (req, res) => {
  // Marks post as deleted without removing from database
  const { postId } = req.params;

  const post = await Post.findOne({ postId });

  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  if (post.isDeleted) {
    throw new ApiError(400, "Post is already deleted");
  }

  post.isDeleted = true;
  post.deletedAt = new Date();
  await post.save();

  return res.status(200).json(
    new ApiResponse(200, post, "Post deleted successfully")
  );
});

// ============================================
// RESTORE DELETED POST
// ============================================
const restorePost = asyncHandler(async (req, res) => {
  // Restores a soft-deleted post back to active
  const { postId } = req.params;

  const post = await Post.findOne({ postId });

  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  if (!post.isDeleted) {
    throw new ApiError(400, "Post is not deleted");
  }

  post.isDeleted = false;
  post.deletedAt = null;
  await post.save();

  return res.status(200).json(
    new ApiResponse(200, post, "Post restored successfully")
  );
});

// ============================================
// EXPORT POSTS TO CSV
// ============================================
const exportPosts = asyncHandler(async (req, res) => {
  // Returns all posts data in CSV-friendly format
  const { includeDeleted = "false" } = req.query;

  const filter = includeDeleted === "true" ? {} : { isDeleted: false };

  const posts = await Post.find(filter)
    .populate("userId", "fullName email")
    .select("postId itemName type category status rewardAmount location createdAt")
    .sort({ createdAt: -1 });

  const csvData = posts.map((post) => ({
    postId: post.postId,
    itemName: post.itemName,
    type: post.type,
    category: post.category,
    status: post.status,
    rewardAmount: post.rewardAmount,
    location: post.location?.name || "N/A",
    ownerName: post.userId?.fullName || "Unknown",
    ownerEmail: post.userId?.email || "N/A",
    createdAt: post.createdAt,
    isDeleted: post.isDeleted,
  }));

  return res.status(200).json(
    new ApiResponse(200, csvData, "Posts exported successfully")
  );
});

// ============================================
// EXPORTS
// ============================================
export {
  getAllPostsAdmin,
  getPostDetailsAdmin,
  softDeletePost,
  restorePost,
  exportPosts,
};