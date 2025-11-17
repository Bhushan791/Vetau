import { Claim } from "../models/claim.model.js";
import { Post } from "../models/post.model.js";
import { ApiError } from "../utils/apiError.js";
import { ApiResponse } from "../utils/apiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { v4 as uuidv4 } from "uuid";

// ============================================
// CLAIM CONTROLLERS
// ============================================


// Creates a new claim on a post by a user
const createClaim = asyncHandler(async (req, res) => {
  const { postId, message } = req.body;

  // Validation
  if (!postId) {
    throw new ApiError(400, "Post ID is required");
  }

  // Check if post exists
  const post = await Post.findOne({ postId });

  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  // Check if user is trying to claim their own post
  if (post.userId.toString() === req.user._id.toString()) {
    throw new ApiError(400, "You cannot claim your own post");
  }

  // Check if post is already claimed or returned
  if (post.status !== "active") {
    throw new ApiError(400, "This post is no longer active");
  }

  // Check if user has already claimed this post
  const existingClaim = await Claim.findOne({
    postId: post._id,
    claimerId: req.user._id,
  });

  if (existingClaim) {
    throw new ApiError(400, "You have already claimed this post");
  }

  // Determine claim type based on post type
  const claimType = post.type === "lost" ? "found" : "lost";

  // Create claim
  const claim = await Claim.create({
    claimId: uuidv4(),
    postId: post._id,
    claimerId: req.user._id,
    claimType,
    message: message || "",
  });

  // Increment post's totalClaims counter
  post.totalClaims += 1;
  await post.save();

  // Populate claim with user and post details
  const populatedClaim = await Claim.findById(claim._id)
    .populate("claimerId", "fullName username email profileImage")
    .populate({
      path: "postId",
      select: "postId type itemName description location images rewardAmount category status",
      populate: {
        path: "userId",
        select: "fullName username profileImage",
      },
    });

  return res
    .status(201)
    .json(new ApiResponse(201, populatedClaim, "Claim created successfully"));
});

// Fetches all claims submitted on a specific post (post owner only)
const getClaimsByPost = asyncHandler(async (req, res) => {
  const { postId } = req.params;
  const { status, page = 1, limit = 10 } = req.query;

  // Check if post exists
  const post = await Post.findOne({ postId });

  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  // Check if user is the post owner
  if (post.userId.toString() !== req.user._id.toString()) {
    throw new ApiError(403, "You can only view claims on your own posts");
  }

  // Build filter
  const filter = { postId: post._id };
  if (status) filter.status = status;

  // Pagination
  const skip = (parseInt(page) - 1) * parseInt(limit);

  const claims = await Claim.find(filter)
    .populate("claimerId", "fullName username email profileImage")
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

  const totalClaims = await Claim.countDocuments(filter);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        claims,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalClaims / parseInt(limit)),
          totalClaims,
          hasMore: skip + claims.length < totalClaims,
        },
      },
      "Claims fetched successfully"
    )
  );
});

// Fetches all claims made by the current logged-in user
const getMyClaims = asyncHandler(async (req, res) => {
  const { status, page = 1, limit = 10 } = req.query;

  // Build filter
  const filter = { claimerId: req.user._id };
  if (status) filter.status = status;

  // Pagination
  const skip = (parseInt(page) - 1) * parseInt(limit);

  const claims = await Claim.find(filter)
    .populate({
      path: "postId",
      select: "postId type itemName description location images rewardAmount category status",
      populate: {
        path: "userId",
        select: "fullName username profileImage",
      },
    })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

  const totalClaims = await Claim.countDocuments(filter);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        claims,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalClaims / parseInt(limit)),
          totalClaims,
          hasMore: skip + claims.length < totalClaims,
        },
      },
      "Your claims fetched successfully"
    )
  );
});

// Fetches all claims made on all posts owned by the user
const getClaimsOnMyPosts = asyncHandler(async (req, res) => {
  const { status, page = 1, limit = 10 } = req.query;

  // Get all posts by current user
  const myPosts = await Post.find({ userId: req.user._id }).select("_id");
  const myPostIds = myPosts.map((post) => post._id);

  if (myPostIds.length === 0) {
    return res.status(200).json(
      new ApiResponse(
        200,
        {
          claims: [],
          pagination: {
            currentPage: 1,
            totalPages: 0,
            totalClaims: 0,
            hasMore: false,
          },
        },
        "No claims found"
      )
    );
  }

  // Build filter
  const filter = { postId: { $in: myPostIds } };
  if (status) filter.status = status;

  // Pagination
  const skip = (parseInt(page) - 1) * parseInt(limit);

  const claims = await Claim.find(filter)
    .populate("claimerId", "fullName username email profileImage")
    .populate({
      path: "postId",
      select: "postId type itemName description location images rewardAmount category status",
    })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

  const totalClaims = await Claim.countDocuments(filter);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        claims,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalClaims / parseInt(limit)),
          totalClaims,
          hasMore: skip + claims.length < totalClaims,
        },
      },
      "Claims on your posts fetched successfully"
    )
  );
});


// Updates a claim’s status (accept/reject) by the post owner
const updateClaimStatus = asyncHandler(async (req, res) => {
  const { claimId } = req.params;
  const { status } = req.body;

  // Validation
  if (!status || !["accepted", "rejected"].includes(status)) {
    throw new ApiError(400, "Valid status is required (accepted or rejected)");
  }

  // Find claim
  const claim = await Claim.findOne({ claimId }).populate("postId");

  if (!claim) {
    throw new ApiError(404, "Claim not found");
  }

  // Check if user is the post owner
  if (claim.postId.userId.toString() !== req.user._id.toString()) {
    throw new ApiError(403, "Only post owner can update claim status");
  }

  // Check if claim is already accepted or rejected
  if (claim.status !== "pending") {
    throw new ApiError(400, `Claim is already ${claim.status}`);
  }

  // Update claim status
  claim.status = status;
  await claim.save();

  // If accepted, update post status to "claimed"
  if (status === "accepted") {
    const post = await Post.findById(claim.postId._id);
    post.status = "claimed";
    await post.save();

    // TODO: Create chat session between post owner and claimer (future implementation)
    // TODO: Send notification to claimer (future implementation)
  }

  // Populate claim details
  const updatedClaim = await Claim.findById(claim._id)
    .populate("claimerId", "fullName username email profileImage")
    .populate({
      path: "postId",
      select: "postId type itemName description location images rewardAmount category status",
    });

  return res
    .status(200)
    .json(
      new ApiResponse(200, updatedClaim, `Claim ${status} successfully`)
    );
});

// Deletes the user’s own claim if it is still pending
const deleteClaim = asyncHandler(async (req, res) => {
  const { claimId } = req.params;

  // Find claim
  const claim = await Claim.findOne({ claimId });

  if (!claim) {
    throw new ApiError(404, "Claim not found");
  }

  // Check if user is the claimer
  if (claim.claimerId.toString() !== req.user._id.toString()) {
    throw new ApiError(403, "You can only delete your own claims");
  }

  // Check if claim is pending
  if (claim.status !== "pending") {
    throw new ApiError(400, `Cannot delete ${claim.status} claims`);
  }

  // Decrement post's totalClaims counter
  const post = await Post.findById(claim.postId);
  if (post) {
    post.totalClaims = Math.max(0, post.totalClaims - 1);
    await post.save();
  }

  // Delete claim
  await Claim.findOneAndDelete({ claimId });

  return res
    .status(200)
    .json(new ApiResponse(200, {}, "Claim deleted successfully"));
});

// ============================================
// EXPORTS
// ============================================

export {
  createClaim,
  getClaimsByPost,
  getMyClaims,
  getClaimsOnMyPosts,
  updateClaimStatus,
  deleteClaim,
};