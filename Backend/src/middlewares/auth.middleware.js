import { User } from "../models/user.model.js";
import { ApiError } from "../utils/apiError.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import jwt from "jsonwebtoken";

// ============================================
// VERIFY JWT - Main Authentication Middleware
// ============================================
export const verifyJWT = asyncHandler(async (req, _, next) => {
  try {
    // Get token from cookies (web) or Authorization header (mobile)
    const token =
      req.cookies?.accessToken ||
      req.header("Authorization")?.replace("Bearer ", "");

    if (!token) {
      throw new ApiError(401, "Unauthorized request");
    }

    // Verify token
    const decodedToken = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET);

    // Find user
    const user = await User.findById(decodedToken?._id).select(
      "-password -refreshToken"
    );

    if (!user) {
      throw new ApiError(401, "Invalid Access Token");
    }

    // ============================================
    // ✅ CHECK IF USER IS SOFT-DELETED
    // ============================================
    if (user.isDeleted) {
      throw new ApiError(403, "Account has been deleted");
    }

    // ============================================
    // ✅ CHECK IF USER IS BANNED
    // ============================================
    if (user.status === "banned") {
      throw new ApiError(403, "Account has been banned");
    }

    // ============================================
    // ✅ UPDATE LAST ACTIVE TIMESTAMP
    // ============================================
    await User.findByIdAndUpdate(
      user._id,
      { lastActive: new Date() },
      { new: true }
    );

    req.user = user;
    next();
  } catch (error) {
    throw new ApiError(401, error?.message || "Invalid access token");
  }
});

// ============================================
// VERIFY ADMIN - Admin Authorization Middleware
// ============================================
export const verifyAdmin = asyncHandler(async (req, _, next) => {
  if (!req.user) {
    throw new ApiError(401, "Unauthorized request");
  }

  if (req.user.role !== "admin") {
    throw new ApiError(403, "Access denied. Admin privileges required.");
  }

  next();
});