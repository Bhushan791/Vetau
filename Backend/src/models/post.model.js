import mongoose, { Schema } from "mongoose";

const postSchema = new Schema(
  {
    postId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    type: {
      type: String,
      enum: ["lost", "found"],
      required: true,
      index: true,
    },
    itemName: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },
    description: {
      type: String,
      required: true,
      trim: true,
    },
    location: {
      type: String,
      trim: true,
      // Mandatory for "found", optional for "lost"
      required: function () {
        return this.type === "found";
      },
    },
    images: {
      type: [String], // Array of image URLs
      validate: {
        validator: function (v) {
          // Mandatory for "found", optional for "lost"
          if (this.type === "found") {
            return v && v.length > 0;
          }
          return true; // Optional for lost
        },
        message: "At least one image is required for found posts",
      },
      default: [],
    },
    rewardAmount: {
      type: Number,
      min: 0,
      // Mandatory for "lost", optional for "found"
      required: function () {
        return this.type === "lost";
      },
    },
    isAnonymous: {
      type: Boolean,
      default: false,
    },
    category: {
      type: String,
      required: true,
      lowercase: true,
      index: true,
    },
    tags: {
      type: [String],
      default: [],
      lowercase: true,
    },
    status: {
      type: String,
      enum: ["active", "claimed", "returned"],
      default: "active",
      index: true,
    },
    // Auto-increment counters
    totalClaims: {
      type: Number,
      default: 0,
    },
    totalComments: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for better query performance
postSchema.index({ type: 1, status: 1 });
postSchema.index({ category: 1, type: 1 });
postSchema.index({ userId: 1, createdAt: -1 });
postSchema.index({ createdAt: -1 }); // For sorting by latest

export const Post = mongoose.model("Post", postSchema);