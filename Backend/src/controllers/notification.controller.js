import { Notification } from "../models/notification.model.js";
import { ApiError } from "../utils/apiError.js";
import { ApiResponse } from "../utils/apiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";

// ============================================
// GET MY NOTIFICATIONS
// ============================================
const getMyNotifications = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  const skip = (page - 1) * limit;

  const notifications = await Notification.find({ userId: req.user._id })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

  const totalNotifications = await Notification.countDocuments({ 
    userId: req.user._id 
  });

  const unreadCount = await Notification.countDocuments({
    userId: req.user._id,
    isRead: false,
  });

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        notifications,
        unreadCount,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalNotifications / limit),
          totalNotifications,
          hasMore: skip + notifications.length < totalNotifications,
        },
      },
      "Notifications fetched successfully"
    )
  );
});

// ============================================
// GET UNREAD COUNT (FOR BADGE)
// ============================================
const getUnreadCount = asyncHandler(async (req, res) => {
  const unreadCount = await Notification.countDocuments({
    userId: req.user._id,
    isRead: false,
  });

  return res.status(200).json(
    new ApiResponse(200, { unreadCount }, "Unread count fetched")
  );
});

// ============================================
// MARK SINGLE AS READ
// ============================================
const markAsRead = asyncHandler(async (req, res) => {
  const { notificationId } = req.params;

  const notification = await Notification.findOneAndUpdate(
    { notificationId, userId: req.user._id },
    { isRead: true },
    { new: true }
  );

  if (!notification) {
    throw new ApiError(404, "Notification not found");
  }

  return res
    .status(200)
    .json(new ApiResponse(200, notification, "Marked as read"));
});

// ============================================
// MARK ALL AS READ
// ============================================
const markAllAsRead = asyncHandler(async (req, res) => {
  const result = await Notification.updateMany(
    { userId: req.user._id, isRead: false },
    { isRead: true }
  );

  return res.status(200).json(
    new ApiResponse(
      200,
      { markedCount: result.modifiedCount },
      "All notifications marked as read"
    )
  );
});

// ============================================
// CLEAR ALL NOTIFICATIONS
// ============================================
const clearAllNotifications = asyncHandler(async (req, res) => {
  const result = await Notification.deleteMany({ userId: req.user._id });

  return res.status(200).json(
    new ApiResponse(
      200,
      { deletedCount: result.deletedCount },
      "All notifications cleared"
    )
  );
});

export {
  getMyNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  clearAllNotifications,
};