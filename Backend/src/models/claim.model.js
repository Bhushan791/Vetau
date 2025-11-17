import mongoose, { Schema } from "mongoose";

const claimSchema = new Schema(
  {
    claimId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    postId: {
      type: Schema.Types.ObjectId,
      ref: "Post",
      required: true,
      index: true,
    },
    claimerId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    claimType: {
      type: String,
      enum: ["found", "lost"], 
      // "found" = claiming on lost post (I found your item)
      // "lost" = claiming on found post (That's my item)
      required: true,
    },
    status: {
      type: String,
      enum: ["pending", "accepted", "rejected"],
      default: "pending",
      index: true,
    },
    message: {
      type: String,
      trim: true,
      default: "",
    },
  },
  { timestamps: true }
);

// Compound index to prevent duplicate claims
claimSchema.index({ postId: 1, claimerId: 1 }, { unique: true });

// Index for filtering by status and sorting by date
claimSchema.index({ status: 1, createdAt: -1 });

// Index for post owner queries
claimSchema.index({ postId: 1, status: 1 });

export const Claim = mongoose.model("Claim", claimSchema);