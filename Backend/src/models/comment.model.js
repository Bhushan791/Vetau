import mongoose from "mongoose";
import { v4 as uuidv4 } from "uuid";

const commentSchema = new mongoose.Schema(
  {
    commentId: {
      type: String,
      default: () => uuidv4(),
      unique: true,
      required: true,
      index: true, // REMOVED DUPLICATE - kept only this one
    },
    postId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Post",
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    content: {
      type: String,
      required: true,
      trim: true,
      minlength: 1,
      maxlength: 500,
    },
    parentCommentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Comment",
      default: null,
      index: true, // REMOVED DUPLICATE - kept only this one
    },

    isEdited: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for faster queries
commentSchema.index({ postId: 1, createdAt: -1 });
// REMOVED: commentSchema.index({ parentCommentId: 1 }); - already defined above
// REMOVED: commentSchema.index({ rootCommentId: 1 }); - field doesn't exist in schema
// REMOVED: commentSchema.index({ commentId: 1 }); - already defined above

export const Comment = mongoose.model("Comment", commentSchema);