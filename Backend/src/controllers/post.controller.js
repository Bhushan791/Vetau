import { Post } from "../models/post.model.js";
import { Category } from "../models/category.model.js";
import { User } from "../models/user.model.js";
import { ApiError } from "../utils/apiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { v4 as uuidv4 } from "uuid";

// ============================================
// POST CONTROLLERS
// ============================================

/**
 * @desc    Create a new post (Lost or Found)
 * @route   POST /api/v1/posts
 * @access  Private
 */
const createPost = asyncHandler(async (req, res) => {
  const { type, itemName, description, location, rewardAmount, isAnonymous, category, tags } = req.body;
  const images = req.files ? req.files.map(file => file.filename) : [];

  if (!type || !itemName || !description || !category) {
    throw new ApiError(400, "Type, item name, description, and category are required");
  }

  if (!["lost", "found"].includes(type)) {
    throw new ApiError(400, "Type must be either 'lost' or 'found'");
  }

  if (type === "lost" && !rewardAmount) {
    throw new ApiError(400, "Reward amount is required for lost posts");
  }

  if (type === "found" && (!location || images.length === 0)) {
    throw new ApiError(400, "Location and at least one image are required for found posts");
  }

  if (isAnonymous) {
    const user = await User.findById(req.user._id);
    if (!user.username) {
      throw new ApiError(400, "Please set a username in your profile to post anonymously");
    }
  }

  const post = await Post.create({
    postId: uuidv4(),
    userId: req.user._id,
    type,
    itemName,
    description,
    location: location || "",
    images: images || [],
    rewardAmount: rewardAmount || 0,
    isAnonymous: isAnonymous || false,
    category: category.toLowerCase(),
    tags: tags || [],
  });

  const populatedPost = await Post.findById(post._id).populate(
    "userId",
    "fullName username email profileImage"
  );

  return res.status(201).json(new ApiResponse(201, populatedPost, "Post created successfully"));
});

/**
 * @desc    Get all posts with filters
 * @route   GET /api/v1/posts
 * @access  Public
 */
const getAllPosts = asyncHandler(async (req, res) => {
  const {
    type,
    category,
    status,
    search,
    location,
    page = 1,
    limit = 10,
  } = req.query;

  // Build filter
  const filter = {};

  if (type) filter.type = type;
  if (category) filter.category = category.toLowerCase();
  if (status) filter.status = status;
  if (location) filter.location = { $regex: location, $options: "i" };

  // Search by item name or description
  if (search) {
    filter.$or = [
      { itemName: { $regex: search, $options: "i" } },
      { description: { $regex: search, $options: "i" } },
      { tags: { $in: [new RegExp(search, "i")] } },
    ];
  }

  // Pagination
  const skip = (parseInt(page) - 1) * parseInt(limit);

  const posts = await Post.find(filter)
    .populate("userId", "fullName username email profileImage")
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

  const totalPosts = await Post.countDocuments(filter);

  // Format response - hide user info if anonymous
  const formattedPosts = posts.map((post) => {
    const postObj = post.toObject();
    if (post.isAnonymous) {
      postObj.userId = {
        username: post.userId.username,
        profileImage: post.userId.profileImage,
      };
    }
    return postObj;
  });

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        posts: formattedPosts,
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

/**
 * @desc    Get single post by ID
 * @route   GET /api/v1/posts/:postId
 * @access  Public
 */
const getPostById = asyncHandler(async (req, res) => {
  const { postId } = req.params;

  const post = await Post.findOne({ postId }).populate(
    "userId",
    "fullName username email profileImage"
  );

  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  // Format response - hide user info if anonymous
  const postObj = post.toObject();
  if (post.isAnonymous) {
    postObj.userId = {
      username: post.userId.username,
      profileImage: post.userId.profileImage,
    };
  }

  return res
    .status(200)
    .json(new ApiResponse(200, postObj, "Post fetched successfully"));
});

/**
 * @desc    Get current user's posts
 * @route   GET /api/v1/posts/my-posts
 * @access  Private
 */
const getMyPosts = asyncHandler(async (req, res) => {
  const { type, status, page = 1, limit = 10 } = req.query;

  // Build filter
  const filter = { userId: req.user._id };
  if (type) filter.type = type;
  if (status) filter.status = status;

  // Pagination
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
      "Your posts fetched successfully"
    )
  );
});

/**
 * @desc    Update post
 * @route   PATCH /api/v1/posts/:postId
 * @access  Private
 */
const updatePost = asyncHandler(async (req, res) => {
  const { postId } = req.params;
  const { description, location, images, rewardAmount, tags } = req.body;

  // Find post
  const post = await Post.findOne({ postId });

  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  // Check ownership
  if (post.userId.toString() !== req.user._id.toString()) {
    throw new ApiError(403, "You are not authorized to update this post");
  }

  // Update fields
  if (description) post.description = description;
  if (location) post.location = location;
  if (images) post.images = images;
  if (rewardAmount !== undefined) post.rewardAmount = rewardAmount;
  if (tags) post.tags = tags;

  await post.save();

  const updatedPost = await Post.findById(post._id).populate(
    "userId",
    "fullName username email profileImage"
  );

  return res
    .status(200)
    .json(new ApiResponse(200, updatedPost, "Post updated successfully"));
});

/**
 * @desc    Update post status
 * @route   PATCH /api/v1/posts/:postId/status
 * @access  Private
 */
const updatePostStatus = asyncHandler(async (req, res) => {
  const { postId } = req.params;
  const { status } = req.body;

  if (!status || !["active", "claimed", "returned"].includes(status)) {
    throw new ApiError(
      400,
      "Valid status is required (active, claimed, returned)"
    );
  }

  // Find post
  const post = await Post.findOne({ postId });

  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  // Check ownership
  if (post.userId.toString() !== req.user._id.toString()) {
    throw new ApiError(403, "You are not authorized to update this post");
  }

  post.status = status;
  await post.save();

  return res
    .status(200)
    .json(new ApiResponse(200, post, "Post status updated successfully"));
});

/**
 * @desc    Delete post
 * @route   DELETE /api/v1/posts/:postId
 * @access  Private
 */
const deletePost = asyncHandler(async (req, res) => {
  const { postId } = req.params;

  // Find post
  const post = await Post.findOne({ postId });

  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  // Check ownership
  if (post.userId.toString() !== req.user._id.toString()) {
    throw new ApiError(403, "You are not authorized to delete this post");
  }

  await Post.findOneAndDelete({ postId });

  return res
    .status(200)
    .json(new ApiResponse(200, {}, "Post deleted successfully"));
});

// ============================================
// EXPORTS
// ============================================

export {
  createPost,
  getAllPosts,
  getPostById,
  getMyPosts,
  updatePost,
  updatePostStatus,
  deletePost,
};