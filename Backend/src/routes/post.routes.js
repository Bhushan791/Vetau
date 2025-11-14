import { Router } from "express";
import {
  createPost,
  getAllPosts,
  getPostById,
  getMyPosts,
  updatePost,
  updatePostStatus,
  deletePost,
} from "../controllers/post.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";
import { upload } from "../middlewares/multer.middleware.js";

const router = Router();

// ============================================
// PUBLIC ROUTES
// ============================================

/**
 * @route   GET /api/v1/posts
 * @desc    Get all posts with filters and pagination
 * @access  Public
 * @query   ?type=lost&category=wallet&status=active&search=passport&location=kathmandu&page=1&limit=10
 */
router.route("/").get(getAllPosts);

/**
 * @route   GET /api/v1/posts/:postId
 * @desc    Get single post by ID
 * @access  Public
 */
router.route("/:postId").get(getPostById);

// ============================================
// PROTECTED ROUTES (Requires Authentication)
// ============================================

/**
 * @route   POST /api/v1/posts
 * @desc    Create a new post (Lost or Found)
 * @access  Private
 * @body    { type, itemName, description, location?, images?, rewardAmount?, isAnonymous?, category, tags? }
 */

router.route("/").post(verifyJWT, upload.array("images"), createPost);

/**
 * @route   GET /api/v1/posts/my-posts
 * @desc    Get current user's posts
 * @access  Private
 * @query   ?type=lost&status=active&page=1&limit=10
 */
router.route("/my-posts").get(verifyJWT, getMyPosts);

/**
 * @route   PATCH /api/v1/posts/:postId
 * @desc    Update post (owner only)
 * @access  Private
 * @body    { description?, location?, images?, rewardAmount?, tags? }
 */
router.route("/:postId").patch(verifyJWT, updatePost);

/**
 * @route   PATCH /api/v1/posts/:postId/status
 * @desc    Update post status (owner only)
 * @access  Private
 * @body    { status: "active" | "claimed" | "returned" }
 */
router.route("/:postId/status").patch(verifyJWT, updatePostStatus);

/**
 * @route   DELETE /api/v1/posts/:postId
 * @desc    Delete post (owner only)
 * @access  Private
 */
router.route("/:postId").delete(verifyJWT, deletePost);

export default router;