import { Router } from "express";
import {
  createClaim,
  getClaimsByPost,
  getMyClaims,
  getClaimsOnMyPosts,
  updateClaimStatus,
  deleteClaim,
} from "../controllers/claim.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";

const router = Router();

// ============================================
// ALL ROUTES ARE PROTECTED (Require Authentication)
// ============================================

/**
 * @route   POST /api/v1/claims
 * @desc    Create a new claim on a post
 * @access  Private
 */
router.route("/").post(verifyJWT, createClaim);

/**
 * @route   GET /api/v1/claims/my-claims
 * @desc    Get all claims made by current user
 * @access  Private
 */
router.route("/my-claims").get(verifyJWT, getMyClaims);

/**
 * @route   GET /api/v1/claims/on-my-posts
 * @desc    Get all claims on current user's posts
 * @access  Private
 */
router.route("/on-my-posts").get(verifyJWT, getClaimsOnMyPosts);

/**
 * @route   GET /api/v1/claims/post/:postId
 * @desc    Get all claims for a specific post (Post owner only)
 * @access  Private
 */
router.route("/post/:postId").get(verifyJWT, getClaimsByPost);

/**
 * @route   PATCH /api/v1/claims/:claimId/status
 * @desc    Update claim status (Accept/Reject) - Post owner only
 * @access  Private
 */
router.route("/:claimId/status").patch(verifyJWT, updateClaimStatus);

/**
 * @route   DELETE /api/v1/claims/:claimId
 * @desc    Delete own claim (Claimer only, pending claims only)
 * @access  Private
 */
router.route("/:claimId").delete(verifyJWT, deleteClaim);

export default router;