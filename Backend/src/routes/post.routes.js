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
 */
router.route("/").get(getAllPosts);

// ============================================
// PROTECTED ROUTES (Requires Authentication)
// ============================================

/**
 * @route   GET /api/v1/posts/my-posts
 * @desc    Get current user's posts
 * @access  Private
 */
router.route("/my-posts").get(verifyJWT, getMyPosts);

/**
 * @route   POST /api/v1/posts
 * @desc    Create a new post
 * @access  Private
 */
router.route("/").post(
  verifyJWT,
  upload.array("images", 5),
  createPost
);

// ============================================
// DYNAMIC ROUTES (PUT ALL OF THESE LAST)
// ============================================

/**
 * @route   GET /api/v1/posts/:postId
 * @desc    Get single post by ID
 * @access  Public
 */
router.route("/:postId").get(getPostById);

/**
 * @route   PATCH /api/v1/posts/:postId
 * @desc    Update post (owner only)
 * @access  Private
 */
router.route("/:postId").patch(
  verifyJWT,
  upload.array("images", 5),
  updatePost
);

/**
 * @route   PATCH /api/v1/posts/:postId/status
 * @desc    Update post status
 * @access  Private
 */
router.route("/:postId/status").patch(verifyJWT, updatePostStatus);

/**
 * @route   DELETE /api/v1/posts/:postId
 * @desc    Delete post
 * @access  Private
 */
router.route("/:postId").delete(verifyJWT, deletePost);

export default router;
