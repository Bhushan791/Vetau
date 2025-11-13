import { User } from "../models/user.model.js";
import { ApiError } from "../utils/apiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { uploadToCloudinary, deleteFromCloudinary } from "../utils/cloudinary.js";
import { v4 as uuidv4 } from "uuid";
import jwt from "jsonwebtoken";
import nodemailer from "nodemailer";
import crypto from "crypto";
import passport from "../config/passport.js";
// ============================================
// HELPER FUNCTIONS
// ============================================

const generateAccessAndRefreshTokens = async (userId) => {
  try {
    const user = await User.findById(userId);
    const accessToken = user.generateAccessToken();
    const refreshToken = user.generateRefreshToken();
    
    user.refreshToken = refreshToken;
    await user.save({ validateBeforeSave: false });
    
    return { accessToken, refreshToken };
  } catch (err) {
    throw new ApiError(500, "Failed to generate tokens");
  }
};

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD,
  },
});

const generateOTP = () => crypto.randomInt(100000, 999999).toString();

const sendOTPEmail = async (email, otp, purpose = "password reset") => {
  const mailOptions = {
    from: process.env.EMAIL_FROM,
    to: email,
    subject: `Lost and Found - Your OTP for ${purpose}`,
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px; background-color: #f4f4f4;">
        <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px;">
          <h2 style="color: #333;">Lost and Found App</h2>
          <p style="font-size: 16px; color: #555;">Your OTP for ${purpose} is:</p>
          <div style="background-color: #007bff; color: white; font-size: 32px; font-weight: bold; padding: 15px; text-align: center; border-radius: 5px; letter-spacing: 5px;">
            ${otp}
          </div>
          <p style="margin-top: 20px; color: #777; font-size: 14px;">This OTP is valid for 10 minutes.</p>
          <p style="color: #777; font-size: 14px;">If you didn't request this, please ignore this email.</p>
        </div>
      </div>
    `,
  };
  await transporter.sendMail(mailOptions);
};
// ============================================
// AUTHENTICATION CONTROLLERS
// ============================================

const registerUser = asyncHandler(async (req, res) => {
  const { fullName, username, email, password, address, authType } = req.body;

  // Validate required fields
  if (!fullName || !username || !authType) {
    throw new ApiError(400, "Full name, username, and authType are required");
  }

  if (authType === "normal" && (!email || !password)) {
    throw new ApiError(400, "Email and password are required for normal signup");
  }

  // Check for existing user
  const existingUser = await User.findOne({ 
    $or: [{ email }, { username }] 
  });
  
  if (existingUser) {
    throw new ApiError(409, "User with this email or username already exists");
  }

  // Handle profile image upload
  let profileImageUrl = "";
  if (req.file?.path) {
    const cloudResp = await uploadToCloudinary(req.file.path);
    profileImageUrl = cloudResp?.secure_url || "";
  }

  // Create user
  const newUser = await User.create({
    userId: uuidv4(),
    fullName,
    username: username.toLowerCase(),
    email: email?.toLowerCase(),
    password,
    address: address || "",
    profileImage: profileImageUrl,
    authType,
  });

  // Get user without sensitive data
  const createdUser = await User.findById(newUser._id).select("-password -refreshToken");

  return res.status(201).json(
    new ApiResponse(201, { user: createdUser }, "User registered successfully")
  );
});

const loginUser = asyncHandler(async (req, res) => {
  const { email, username, password } = req.body;

  // Validate input
  if (!username && !email) {
    throw new ApiError(400, "Username or email is required");
  }

  // Find user
  const user = await User.findOne({ 
    $or: [{ username }, { email }] 
  });

  if (!user) {
    throw new ApiError(404, "User does not exist");
  }

  // Verify password for normal auth
  if (user.authType === "normal") {
    if (!password) {
      throw new ApiError(400, "Password is required");
    }
    const isPasswordValid = await user.isPasswordCorrect(password);
    if (!isPasswordValid) {
      throw new ApiError(401, "Invalid credentials");
    }
  }

  // Generate tokens
  const { accessToken, refreshToken } = await generateAccessAndRefreshTokens(user._id);

  // Get user data without sensitive fields
  const loggedInUser = await User.findById(user._id).select("-password -refreshToken");

  const options = { httpOnly: true, secure: true };

  // Set refresh token in cookie and return access token in response
  return res
    .status(200)
    .cookie("refreshToken", refreshToken, options)
    .json(
      new ApiResponse(
        200,
        { user: loggedInUser, accessToken },
        "User logged in successfully"
      )
    );
});

const logoutUser = asyncHandler(async (req, res) => {
  // Clear refresh token from database
  await User.findByIdAndUpdate(
    req.user._id,
    { $unset: { refreshToken: 1 } },
    { new: true }
  );

  const options = { httpOnly: true, secure: true };

  return res
    .status(200)
    .clearCookie("refreshToken", options)
    .json(new ApiResponse(200, {}, "User logged out successfully"));
});

const refreshAccessToken = asyncHandler(async (req, res) => {
  const incomingRefreshToken = req.cookies?.refreshToken || req.body.refreshToken;

  if (!incomingRefreshToken) {
    throw new ApiError(401, "Unauthorized request");
  }

  try {
    const decodedToken = jwt.verify(
      incomingRefreshToken,
      process.env.REFRESH_TOKEN_SECRET
    );

    const user = await User.findById(decodedToken?._id);

    if (!user) {
      throw new ApiError(401, "Invalid refresh token");
    }

    if (incomingRefreshToken !== user?.refreshToken) {
      throw new ApiError(401, "Refresh token is expired or used");
    }

    // Generate new tokens
    const { accessToken, refreshToken: newRefreshToken } = await generateAccessAndRefreshTokens(user._id);

    const options = { httpOnly: true, secure: true };

    return res
      .status(200)
      .cookie("refreshToken", newRefreshToken, options)
      .json(
        new ApiResponse(
          200,
          { accessToken },
          "Access token refreshed successfully"
        )
      );
  } catch (error) {
    throw new ApiError(401, error?.message || "Invalid refresh token");
  }
});



const googleAuth = passport.authenticate("google", {
  scope: ["profile", "email"],
});

// Google OAuth Callback
const googleAuthCallback = [
  passport.authenticate("google", { 
    session: false, 
    failureRedirect: "http://localhost:3000/login?error=auth_failed" 
  }),
  asyncHandler(async (req, res) => {
    // Generate tokens for the authenticated user
    const { accessToken, refreshToken } = await generateAccessAndRefreshTokens(req.user._id);

    // Get user data
    const user = await User.findById(req.user._id).select("-password -refreshToken");

    // Redirect to frontend with tokens (change URL based on your frontend)
    const redirectUrl = `http://localhost:3000/auth/success?accessToken=${accessToken}&refreshToken=${refreshToken}&userId=${user._id}`;
    
    res.redirect(redirectUrl);
  }),
];


// ============================================
// PROFILE MANAGEMENT
// ============================================

const getCurrentUser = asyncHandler(async (req, res) => {
  return res
    .status(200)
    .json(new ApiResponse(200, req.user, "User fetched successfully"));
});

const updateAccountDetails = asyncHandler(async (req, res) => {
  const { fullName, address } = req.body;

  if (!fullName && !address) {
    throw new ApiError(400, "At least one field is required to update");
  }

  const updateFields = {};
  if (fullName) updateFields.fullName = fullName;
  if (address) updateFields.address = address;

  const user = await User.findByIdAndUpdate(
    req.user?._id,
    { $set: updateFields },
    { new: true }
  ).select("-password -refreshToken");

  return res
    .status(200)
    .json(new ApiResponse(200, user, "Account details updated successfully"));
});

const updateUserProfileImage = asyncHandler(async (req, res) => {
  const profileImageLocalPath = req.file?.path;

  if (!profileImageLocalPath) {
    throw new ApiError(400, "Profile image file is required");
  }

  // Delete old image from Cloudinary
  const user = await User.findById(req.user?._id);
  if (user.profileImage) {
    const publicId = user.profileImage.split('/').pop().split('.')[0];
    await deleteFromCloudinary(publicId);
  }

  // Upload new image
  const uploadedImage = await uploadToCloudinary(profileImageLocalPath);

  if (!uploadedImage?.url) {
    throw new ApiError(500, "Error while uploading profile image");
  }

  const updatedUser = await User.findByIdAndUpdate(
    req.user?._id,
    { $set: { profileImage: uploadedImage.url } },
    { new: true }
  ).select("-password -refreshToken");

  return res
    .status(200)
    .json(new ApiResponse(200, updatedUser, "Profile image updated successfully"));
});

const deleteAccount = asyncHandler(async (req, res) => {
  const userId = req.user?._id;

  // Delete profile image from Cloudinary
  const user = await User.findById(userId);
  if (user.profileImage) {
    const publicId = user.profileImage.split('/').pop().split('.')[0];
    await deleteFromCloudinary(publicId);
  }

  // Delete user
  await User.findByIdAndDelete(userId);

  const options = { httpOnly: true, secure: true };

  return res
    .status(200)
    .clearCookie("refreshToken", options)
    .json(new ApiResponse(200, {}, "Account deleted successfully"));
});

// ============================================
// PASSWORD MANAGEMENT
// ============================================

const changeCurrentPassword = asyncHandler(async (req, res) => {
  const { oldPassword, newPassword } = req.body;

  if (!oldPassword || !newPassword) {
    throw new ApiError(400, "Old password and new password are required");
  }

  const user = await User.findById(req.user?._id);

  if (!user) {
    throw new ApiError(401, "Unauthorized");
  }

  if (user.authType === "google") {
    throw new ApiError(400, "Google users cannot change password");
  }

  const isPasswordCorrect = await user.isPasswordCorrect(oldPassword);

  if (!isPasswordCorrect) {
    throw new ApiError(400, "Old password is incorrect");
  }

  user.password = newPassword;
  await user.save({ validateBeforeSave: false });

  return res
    .status(200)
    .json(new ApiResponse(200, {}, "Password changed successfully"));
});

const forgotPassword = asyncHandler(async (req, res) => {
  const { email } = req.body;

  if (!email) {
    throw new ApiError(400, "Email is required");
  }

  const user = await User.findOne({ email: email.toLowerCase() });

  if (!user) {
    throw new ApiError(404, "User with this email does not exist");
  }

  if (user.authType === "google") {
    throw new ApiError(400, "Google users cannot reset password");
  }

  const otp = generateOTP();

  user.passwordResetOTP = otp;
  user.passwordResetOTPExpiry = Date.now() + 10 * 60 * 1000;
  await user.save({ validateBeforeSave: false });

 try {
  await sendOTPEmail(email, otp, "password reset");
} catch (error) {
  console.error("EMAIL ERROR DETAILS:", error); // Add this
  user.passwordResetOTP = undefined;
  user.passwordResetOTPExpiry = undefined;
  await user.save({ validateBeforeSave: false });
  throw new ApiError(500, "Failed to send OTP email. Please try again.");
}

  return res
    .status(200)
    .json(new ApiResponse(200, {}, "OTP sent to your email successfully"));
});

const verifyPasswordResetOTP = asyncHandler(async (req, res) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    throw new ApiError(400, "Email and OTP are required");
  }

  const user = await User.findOne({ email: email.toLowerCase() });

  if (!user) {
    throw new ApiError(404, "User not found");
  }

  if (!user.passwordResetOTP || !user.passwordResetOTPExpiry) {
    throw new ApiError(400, "No OTP request found. Please request a new OTP.");
  }

  if (Date.now() > user.passwordResetOTPExpiry) {
    user.passwordResetOTP = undefined;
    user.passwordResetOTPExpiry = undefined;
    await user.save({ validateBeforeSave: false });
    throw new ApiError(400, "OTP has expired. Please request a new one.");
  }

  if (user.passwordResetOTP !== otp) {
    throw new ApiError(400, "Invalid OTP");
  }

  user.isOTPVerified = true;
  await user.save({ validateBeforeSave: false });

  return res
    .status(200)
    .json(new ApiResponse(200, {}, "OTP verified successfully. You can now reset your password."));
});

const resetPasswordWithOTP = asyncHandler(async (req, res) => {
  const { email, newPassword } = req.body;

  if (!email || !newPassword) {
    throw new ApiError(400, "Email and new password are required");
  }

  const user = await User.findOne({ email: email.toLowerCase() });

  if (!user) {
    throw new ApiError(404, "User not found");
  }

  if (!user.isOTPVerified) {
    throw new ApiError(400, "OTP not verified. Please verify OTP first.");
  }

  user.password = newPassword;
  user.passwordResetOTP = undefined;
  user.passwordResetOTPExpiry = undefined;
  user.isOTPVerified = undefined;
  await user.save({ validateBeforeSave: false });

  return res
    .status(200)
    .json(new ApiResponse(200, {}, "Password reset successfully. You can now login."));
});

// ============================================
// EXPORTS
// ============================================

export {
  registerUser,
  loginUser,
  logoutUser,
  refreshAccessToken,
  googleAuthCallback,
  googleAuth,
  getCurrentUser,
  updateAccountDetails,
  updateUserProfileImage,
  deleteAccount,
  changeCurrentPassword,
  forgotPassword,
  verifyPasswordResetOTP,
  resetPasswordWithOTP,
};