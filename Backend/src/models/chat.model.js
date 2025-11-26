import mongoose from "mongoose";
import { v4 as uuidv4 } from "uuid";

const chatSchema = new mongoose.Schema(
  {
    chatId: {
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
    claimId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Claim",
      required: true,
    },
    participants: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true,
      },
    ],
    lastMessage: {
      type: String,
      default: "",
    },
    lastMessageAt: {
      type: Date,
      default: Date.now,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Index for faster queries
chatSchema.index({ participants: 1 });
// REMOVED: chatSchema.index({ chatId: 1 }); - already defined above
// REMOVED: chatSchema.index({ postId: 1 }); - already defined above

// Validation: Exactly 2 participants
chatSchema.pre("save", function (next) {
  if (this.participants.length !== 2) {
    next(new Error("Chat must have exactly 2 participants"));
  }
  next();
});

export const Chat = mongoose.model("Chat", chatSchema);