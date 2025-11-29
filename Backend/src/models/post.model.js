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

    // Location
    location: {
      name: {
        type: String,
        required: true,
        trim: true,
      },
      coordinates: {
        type: [Number], // [lng, lat]
        default: null,
        validate: {
          validator: function (v) {
            if (v === null) return true;
            return Array.isArray(v) && v.length === 2;
          },
          message: "Coordinates must be [longitude, latitude] or null",
        },
      },
    },

    images: {
      type: [String],
      validate: {
        validator: function (v) {
          if (this.type === "found") return v && v.length > 0;
          return true;
        },
        message: "At least one image is required for found posts",
      },
      default: [],
    },

    rewardAmount: {
      type: Number,
      min: 0,
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

    totalClaims: {
      type: Number,
      default: 0,
    },

    totalComments: {
      type: Number,
      default: 0,
    },

    // NEW FIELDS
    isDeleted: {
      type: Boolean,
      default: false,
      index: true,
    },

    deletedAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

// Indexes
postSchema.index({ type: 1, status: 1 });
postSchema.index({ category: 1, type: 1 });
postSchema.index({ userId: 1, createdAt: -1 });
postSchema.index({ createdAt: -1 });
postSchema.index({ rewardAmount: -1 });
postSchema.index({ "location.coordinates": "2dsphere" });

export const Post = mongoose.model("Post", postSchema);
