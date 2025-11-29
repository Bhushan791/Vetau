import { Post } from "../models/post.model.js";
import { Category } from "../models/category.model.js";
import { User } from "../models/user.model.js";
import { ApiError } from "../utils/apiError.js";
import { ApiResponse } from "../utils/apiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { uploadToCloudinary } from "../utils/cloudinary.js";
import { filterPostsByDistance } from "../utils/locationHelper.js";
import { v4 as uuidv4 } from "uuid";
import fs from "fs";
import { formatPostWithAnonymous } from "../utils/userHelper.js";

// ============================================
// CREATE POST
// ============================================
const createPost = asyncHandler(async (req, res) => {
  try {
    const {
      type,
      itemName,
      description,
      location,
      rewardAmount,
      isAnonymous,
      category,
      tags,
    } = req.body;

    // Validation
    if (!type || !itemName || !description || !category || !location) {
      throw new ApiError(
        400,
        "Type, item name, description, category, and location are required"
      );
    }

    if (!["lost", "found"].includes(type)) {
      throw new ApiError(400, "Type must be either 'lost' or 'found'");
    }

    if (type === "lost" && !rewardAmount) {
      throw new ApiError(400, "Reward amount is required for lost posts");
    }

    if (type === "found" && (!req.files || req.files.length === 0)) {
      throw new ApiError(
        400,
        "At least one image is required for found posts"
      );
    }

    // Parse location (can be string or object)
    let locationData;
    if (typeof location === "string") {
      try {
        locationData = JSON.parse(location);
      } catch {
        // If not JSON, treat as plain text
        locationData = { name: location, coordinates: null };
      }
    } else {
      locationData = location;
    }

    // Validate location format
    if (!locationData.name) {
      throw new ApiError(400, "Location name is required");
    }

    // If coordinates provided, validate format
    if (locationData.latitude && locationData.longitude) {
      locationData.coordinates = [
        parseFloat(locationData.longitude),
        parseFloat(locationData.latitude),
      ];
    } else if (locationData.coordinates) {
      // Already in [lng, lat] format
      locationData.coordinates = locationData.coordinates;
    } else {
      // No coordinates (typed manually)
      locationData.coordinates = null;
    }

    // ============================================
    // AUTO-CREATE CATEGORY IF IT DOESN'T EXIST
    // ============================================
    const categoryLower = category.toLowerCase().trim();
    
    let categoryExists = await Category.findOne({
      name: categoryLower,
    });

    // If category doesn't exist, create it automatically
    if (!categoryExists) {
      categoryExists = await Category.create({
        categoryId: uuidv4(),
        name: categoryLower,
        description: `User-created category: ${categoryLower}`,
        icon: "",
        isActive: true,
      });
    }

    const finalCategory = categoryLower;
    // ============================================

    // Check username for anonymous posts
    if (isAnonymous) {
      const user = await User.findById(req.user._id);
      if (!user.username) {
        throw new ApiError(
          400,
          "Please set a username in your profile to post anonymously"
        );
      }
    }

    // Upload images to Cloudinary
    const imageUrls = [];
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        const cloudResp = await uploadToCloudinary(file.path);
        if (cloudResp?.secure_url) {
          imageUrls.push(cloudResp.secure_url);
        }
      }
    }

    // Create post
    const post = await Post.create({
      postId: uuidv4(),
      userId: req.user._id,
      type,
      itemName,
      description,
      location: {
        name: locationData.name,
        coordinates: locationData.coordinates,
      },
      images: imageUrls,
      rewardAmount: rewardAmount || 0,
      isAnonymous: isAnonymous || false,
      category: finalCategory,
      tags: tags || [],
    });

    const populatedPost = await Post.findById(post._id).populate(
      "userId",
      "fullName username email profileImage"
    );

    return res
      .status(201)
      .json(new ApiResponse(201, populatedPost, "Post created successfully"));
  } catch (error) {
    if (req.files && req.files.length > 0) {
      req.files.forEach((file) => {
        if (file.path && fs.existsSync(file.path)) {
          fs.unlinkSync(file.path);
        }
      });
    }
    throw error;
  }
});

// ============================================
// ✅ GET ALL POSTS WITH FILTERS (UPDATED)
// ============================================
const getAllPosts = asyncHandler(async (req, res) => {
  const {
    type,
    category,
    categories, // Multiple categories (comma-separated)
    status,
    search,
    nearMe,
    latitude,
    longitude,
    radius = 7,
    highReward, // Filter rewards >= 2000
    page = 1,
    limit = 10,
  } = req.query;

  // Build filter
  const filter = {
    isDeleted: false, // ✅ EXCLUDE SOFT-DELETED POSTS
  };

  // Type filter
  if (type) filter.type = type;

  // Single category filter
  if (category) filter.category = category.toLowerCase();

  // Multiple categories filter
  if (categories) {
    const categoryArray = categories.split(",").map((c) => c.toLowerCase());
    filter.category = { $in: categoryArray };
  }

  // Status filter
  if (status) filter.status = status;

  // High reward filter
  if (highReward === "true") {
    filter.rewardAmount = { $gte: 2000 };
  }

  // Keyword search (item name, description, tags)
  if (search) {
    filter.$or = [
      { itemName: { $regex: search, $options: "i" } },
      { description: { $regex: search, $options: "i" } },
      { tags: { $in: [new RegExp(search, "i")] } },
    ];
  }

  // Fetch posts
  const posts = await Post.find(filter)
    .populate("userId", "fullName username email profileImage")
    .sort({ createdAt: -1 });

  let finalPosts = posts;

  // Near Me filter (TURF.js)
  if (nearMe === "true" && latitude && longitude) {
    const userLat = parseFloat(latitude);
    const userLng = parseFloat(longitude);
    const searchRadius = parseFloat(radius);

    // Filter posts within radius
    finalPosts = filterPostsByDistance(posts, userLat, userLng, searchRadius);
  }

  // Pagination
  const skip = (parseInt(page) - 1) * parseInt(limit);
  const paginatedPosts = finalPosts.slice(skip, skip + parseInt(limit));

  // Format response (hide user info if anonymous)
  const formattedPosts = paginatedPosts.map((post) => formatPostWithAnonymous(post));

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        posts: formattedPosts,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(finalPosts.length / parseInt(limit)),
          totalPosts: finalPosts.length,
          hasMore: skip + paginatedPosts.length < finalPosts.length,
        },
      },
      "Posts fetched successfully"
    )
  );
});

// ============================================
// ✅ GET POST BY ID (UPDATED)
// ============================================
const getPostById = asyncHandler(async (req, res) => {
  const { postId } = req.params;

  const post = await Post.findOne({ 
    postId,
    isDeleted: false // ✅ EXCLUDE SOFT-DELETED POSTS
  }).populate("userId", "fullName username email profileImage");

  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  const postObj = formatPostWithAnonymous(post);

  return res
    .status(200)
    .json(new ApiResponse(200, postObj, "Post fetched successfully"));
});

// ============================================
// ✅ GET MY POSTS (UPDATED)
// ============================================
const getMyPosts = asyncHandler(async (req, res) => {
  const { type, status, page = 1, limit = 10 } = req.query;

  const filter = { 
    userId: req.user._id,
    isDeleted: false // ✅ EXCLUDE SOFT-DELETED POSTS
  };
  
  if (type) filter.type = type;
  if (status) filter.status = status;

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

// ============================================
// UPDATE POST
// ============================================
const updatePost = asyncHandler(async (req, res) => {
  try {
    const { postId } = req.params;
    const { description, location, rewardAmount, tags } = req.body;

    const post = await Post.findOne({ 
      postId,
      isDeleted: false // ✅ Cannot update soft-deleted posts
    });

    if (!post) {
      throw new ApiError(404, "Post not found");
    }

    if (post.userId.toString() !== req.user._id.toString()) {
      throw new ApiError(403, "You are not authorized to update this post");
    }

    // Update fields
    if (description) post.description = description;
    if (rewardAmount !== undefined) post.rewardAmount = rewardAmount;
    if (tags) post.tags = tags;

    // Update location if provided
    if (location) {
      let locationData;
      if (typeof location === "string") {
        try {
          locationData = JSON.parse(location);
        } catch {
          locationData = { name: location, coordinates: null };
        }
      } else {
        locationData = location;
      }

      if (locationData.latitude && locationData.longitude) {
        post.location = {
          name: locationData.name,
          coordinates: [
            parseFloat(locationData.longitude),
            parseFloat(locationData.latitude),
          ],
        };
      } else {
        post.location = {
          name: locationData.name,
          coordinates: locationData.coordinates || null,
        };
      }
    }

    // Handle new images
    if (req.files && req.files.length > 0) {
      const imageUrls = [];
      for (const file of req.files) {
        const cloudResp = await uploadToCloudinary(file.path);
        if (cloudResp?.secure_url) {
          imageUrls.push(cloudResp.secure_url);
        }
      }
      post.images = [...post.images, ...imageUrls];
    }

    await post.save();

    const updatedPost = await Post.findById(post._id).populate(
      "userId",
      "fullName username email profileImage"
    );

    return res
      .status(200)
      .json(new ApiResponse(200, updatedPost, "Post updated successfully"));
  } catch (error) {
    if (req.files && req.files.length > 0) {
      req.files.forEach((file) => {
        if (file.path && fs.existsSync(file.path)) {
          fs.unlinkSync(file.path);
        }
      });
    }
    throw error;
  }
});

// ============================================
// UPDATE POST STATUS
// ============================================
const updatePostStatus = asyncHandler(async (req, res) => {
  const { postId } = req.params;
  const { status } = req.body;

  if (!status || !["active", "claimed", "returned"].includes(status)) {
    throw new ApiError(
      400,
      "Valid status is required (active, claimed, returned)"
    );
  }

  const post = await Post.findOne({ 
    postId,
    isDeleted: false // ✅ Cannot update soft-deleted posts
  });

  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  if (post.userId.toString() !== req.user._id.toString()) {
    throw new ApiError(403, "You are not authorized to update this post");
  }

  post.status = status;
  await post.save();

  return res
    .status(200)
    .json(new ApiResponse(200, post, "Post status updated successfully"));
});

// ============================================
// ✅ DELETE POST (SOFT DELETE - CHANGED FROM HARD DELETE)
// ============================================
const deletePost = asyncHandler(async (req, res) => {
  const { postId } = req.params;

  const post = await Post.findOne({ 
    postId,
    isDeleted: false // ✅ Prevent double-deletion
  });

  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  if (post.userId.toString() !== req.user._id.toString()) {
    throw new ApiError(403, "You are not authorized to delete this post");
  }

  // ✅ SOFT DELETE: Set isDeleted flag instead of removing from DB
  await Post.findOneAndUpdate(
    { postId },
    { 
      isDeleted: true, 
      deletedAt: new Date() 
    },
    { new: true }
  );

  return res
    .status(200)
    .json(new ApiResponse(200, {}, "Post deleted successfully"));
});

export {
  createPost,
  getAllPosts,
  getPostById,
  getMyPosts,
  updatePost,
  updatePostStatus,
  deletePost,
};