import { SavedPost } from "../models/savedPost.model.js";
import { Post } from "../models/post.model.js";
import { ApiError } from "../utils/apiError.js";
import { ApiResponse } from "../utils/apiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";

/**
 * @route POST /api/v1/saved-posts/save/:postId
 * @desc Save a post
 * @access Private
 */
export const savePost = asyncHandler(async (req, res) => {
  const { postId } = req.params; // UUID string
  const userId = req.user._id;

  // Check if post exists
  const post = await Post.findOne({ postId });
  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  // Check if already saved
  const existingSavedPost = await SavedPost.findOne({ userId, postId });
  if (existingSavedPost) {
    throw new ApiError(400, "Post already saved");
  }

  // Save the post with UUID
  const savedPost = await SavedPost.create({
    userId,
    postId, // Store UUID directly
  });

  return res
    .status(201)
    .json(new ApiResponse(201, savedPost, "Post saved successfully"));
});

/**
 * @route DELETE /api/v1/saved-posts/unsave/:postId
 * @desc Unsave a post
 * @access Private
 */
export const unsavePost = asyncHandler(async (req, res) => {
  const { postId } = req.params; // UUID string
  const userId = req.user._id;

  // Find and delete
  const savedPost = await SavedPost.findOneAndDelete({ userId, postId });

  if (!savedPost) {
    throw new ApiError(404, "Saved post not found");
  }

  return res
    .status(200)
    .json(new ApiResponse(200, null, "Post unsaved successfully"));
});

/**
 * @route GET /api/v1/saved-posts/my-saved-posts
 * @desc Get all saved posts for logged-in user
 * @access Private
 */
export const getMySavedPosts = asyncHandler(async (req, res) => {
  const userId = req.user._id;
  const { page = 1, limit = 10 } = req.query;

  const skip = (parseInt(page) - 1) * parseInt(limit);

  // Get saved posts
  const savedPosts = await SavedPost.find({ userId })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

  // Get all postIds
  const postIds = savedPosts.map((sp) => sp.postId);

  // Fetch actual posts with user details
  const posts = await Post.find({ postId: { $in: postIds } }).populate({
    path: "userId",
    select: "fullName username profileImage",
  });

  // Map posts to savedPosts order
  const postsMap = {};
  posts.forEach((post) => {
    postsMap[post.postId] = post;
  });

  const savedPostsWithDetails = savedPosts.map((sp) => ({
    savedPostId: sp.savedPostId,
    createdAt: sp.createdAt,
    post: postsMap[sp.postId] || null,
  }));

  // Get total count
  const totalSavedPosts = await SavedPost.countDocuments({ userId });

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        savedPosts: savedPostsWithDetails,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalSavedPosts / parseInt(limit)),
          totalSavedPosts,
          limit: parseInt(limit),
        },
      },
      "Saved posts fetched successfully"
    )
  );
});

/**
 * @route GET /api/v1/saved-posts/check/:postId
 * @desc Check if a post is saved by user
 * @access Private
 */
export const checkIfPostSaved = asyncHandler(async (req, res) => {
  const { postId } = req.params; // UUID string
  const userId = req.user._id;

  const savedPost = await SavedPost.findOne({ userId, postId });

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        isSaved: !!savedPost,
      },
      savedPost ? "Post is saved" : "Post is not saved"
    )
  );
});