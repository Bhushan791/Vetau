import mongoose, { Schema } from "mongoose";
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";

const userSchema = new Schema(
  {
    userId: {
      type: String,
      required: true,
      unique: true,
    },

    fullName: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },

    username: {
      type: String,
      lowercase: true,
      trim: true,
      index: true,
    },

    email: {
      type: String,
      required: function () {
        return this.authType === "normal";
      },
      unique: true,
      sparse: true,
      lowercase: true,
      trim: true,
    },

    password: {
      type: String,
      required: function () {
        return this.authType === "normal";
      },
    },

    address: {
      type: String,
      trim: true,
      default: "",
    },

    profileImage: {
      type: String,
      default: "",
    },

    authType: {
      type: String,
      enum: ["normal", "google"],
      required: true,
      default: "normal",
    },

    refreshToken: {
      type: String,
    },

    // Password Reset OTP Fields
    passwordResetOTP: {
      type: String,
    },
    passwordResetOTPExpiry: {
      type: Date,
    },
    isOTPVerified: {
      type: Boolean,
      default: false,
    },

    // FCM Token
    fcmToken: {
      type: String,
      default: null,
    },

    // NEW FIELDS
    role: {
      type: String,
      enum: ["user", "admin"],
      default: "user",
      index: true,
    },

    status: {
      type: String,
      enum: ["active", "banned"],
      default: "active",
      index: true,
    },

    isDeleted: {
      type: Boolean,
      default: false,
      index: true,
    },

    deletedAt: {
      type: Date,
      default: null,
    },

    lastActive: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

// Hash password
userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

// Compare password
userSchema.methods.isPasswordCorrect = async function (password) {
  return await bcrypt.compare(password, this.password);
};

// Access Token
userSchema.methods.generateAccessToken = function () {
  return jwt.sign(
    {
      _id: this._id,
      email: this.email,
      username: this.username,
      fullName: this.fullName,
      authType: this.authType,
      role: this.role,
      status: this.status,
    },
    process.env.ACCESS_TOKEN_SECRET,
    { expiresIn: process.env.ACCESS_TOKEN_EXPIRY }
  );
};

// Refresh Token
userSchema.methods.generateRefreshToken = function () {
  return jwt.sign(
    { _id: this._id },
    process.env.REFRESH_TOKEN_SECRET,
    { expiresIn: process.env.REFRESH_TOKEN_EXPIRY }
  );
};

export const User = mongoose.model("User", userSchema);
