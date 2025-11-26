import mongoose from "mongoose";
import { v4 as uuidv4 } from "uuid";

const savedPostSchema = new mongoose.Schema(
  {
    savedPostId: {
      type: String,
      default: () => uuidv4(),
      unique: true,
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    postId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Post",
      required: true,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index: One user can save a post only once
savedPostSchema.index({ userId: 1, postId: 1 }, { unique: true });

// Index for faster queries
savedPostSchema.index({ userId: 1, createdAt: -1 });

export const SavedPost = mongoose.model("SavedPost", savedPostSchema);