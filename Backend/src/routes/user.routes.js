import { Router } from "express";
import {
  registerUser,
  loginUser,
  logoutUser,
  refreshAccessToken,
  googleAuthCallback,
  getCurrentUser,
  updateAccountDetails,
  updateUserProfileImage,
  deleteAccount,
  changeCurrentPassword,
  forgotPassword,
  verifyPasswordResetOTP,
  resetPasswordWithOTP,
} from "../controllers/user.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";
import { upload } from "../middlewares/multer.middleware.js";

const router = Router();

// ============================================
// PUBLIC ROUTES (No authentication required)
// ============================================

/**
 * @route   POST /api/v1/users/register
 * @desc    Register a new user
 * @access  Public
 */
router.route("/register").post(
  upload.single("profileImage"), // Multer middleware for single file upload
  registerUser
);

/**
 * @route   POST /api/v1/users/login
 * @desc    Login user
 * @access  Public
 */
router.route("/login").post(loginUser);

/**
 * @route   POST /api/v1/users/refresh-token
 * @desc    Refresh access token using refresh token
 * @access  Public
 */
router.route("/refresh-token").post(refreshAccessToken);

/**
 * @route   GET /api/v1/users/google/callback
 * @desc    Google OAuth callback (placeholder)
 * @access  Public
 */
router.route("/google/callback").get(googleAuthCallback);

// ============================================
// PASSWORD RESET ROUTES (Public - OTP based)
// ============================================

/**
 * @route   POST /api/v1/users/forgot-password
 * @desc    Send OTP to email for password reset
 * @access  Public
 */
router.route("/forgot-password").post(forgotPassword);

/**
 * @route   POST /api/v1/users/verify-reset-otp
 * @desc    Verify OTP for password reset
 * @access  Public
 */
router.route("/verify-reset-otp").post(verifyPasswordResetOTP);

/**
 * @route   POST /api/v1/users/reset-password
 * @desc    Reset password after OTP verification
 * @access  Public
 */
router.route("/reset-password").post(resetPasswordWithOTP);

// ============================================
// PROTECTED ROUTES (Authentication required)
// ============================================

/**
 * @route   POST /api/v1/users/logout
 * @desc    Logout user
 * @access  Private
 */
router.route("/logout").post(verifyJWT, logoutUser);

/**
 * @route   GET /api/v1/users/current-user
 * @desc    Get current logged-in user details
 * @access  Private
 */
router.route("/current-user").get(verifyJWT, getCurrentUser);

/**
 * @route   PATCH /api/v1/users/update-account
 * @desc    Update user account details (fullName, address)
 * @access  Private
 */
router.route("/update-account").patch(verifyJWT, updateAccountDetails);

/**
 * @route   PATCH /api/v1/users/update-profile-image
 * @desc    Update user profile image
 * @access  Private
 */
router.route("/update-profile-image").patch(
  verifyJWT,
  upload.single("profileImage"), // Multer for profile image upload
  updateUserProfileImage
);

/**
 * @route   POST /api/v1/users/change-password
 * @desc    Change current password (requires old password)
 * @access  Private
 */
router.route("/change-password").post(verifyJWT, changeCurrentPassword);

/**
 * @route   DELETE /api/v1/users/delete-account
 * @desc    Delete user account permanently
 * @access  Private
 */
router.route("/delete-account").delete(verifyJWT, deleteAccount);

export default router;