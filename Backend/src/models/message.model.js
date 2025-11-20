import mongoose from "mongoose";
import { v4 as uuidv4 } from "uuid";

const messageSchema = new mongoose.Schema(
  {
    messageId: {
      type: String,
      default: () => uuidv4(),
      unique: true,
      required: true,
    },
    chatId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Chat",
      required: true,
      index: true,
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    content: {
      type: String,
      default: "",
    },
    media: [
      {
        type: String, // Cloudinary URLs
      },
    ],
    messageType: {
      type: String,
      enum: ["text", "image", "voice"],
      default: "text",
      required: true,
    },
    isRead: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for faster queries
messageSchema.index({ chatId: 1, createdAt: -1 });
messageSchema.index({ messageId: 1 });

// Validation: Either content or media must be present
messageSchema.pre("save", function (next) {
  if (!this.content && (!this.media || this.media.length === 0)) {
    next(new Error("Message must have either content or media"));
  }
  next();
});

export const Message = mongoose.model("Message", messageSchema);