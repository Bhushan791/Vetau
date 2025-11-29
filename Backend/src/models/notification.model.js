import mongoose from "mongoose";

const notificationSchema = new mongoose.Schema(
  {
    notificationId: { 
      type: String, 
      required: true, 
      unique: true 
    },
    userId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: "User", 
      required: true,
      index: true
    },
    type: { 
      type: String, 
      enum: ["claim", "message", "comment", "status_update"], 
      required: true 
    },
    title: { 
      type: String, 
      required: true 
    },
    body: { 
      type: String, 
      required: true 
    },
    data: { 
      type: Object, 
      default: {} 
    },
    isRead: { 
      type: Boolean, 
      default: false,
      index: true
    },
    isSent: { 
      type: Boolean, 
      default: false 
    },
  },
  { timestamps: true }
);

// Compound index for efficient queries
notificationSchema.index({ userId: 1, isRead: 1, createdAt: -1 });

export const Notification = mongoose.model("Notification", notificationSchema);