import { Chat } from "../models/chat.model.js";
import { Message } from "../models/message.model.js";
import { ApiResponse } from "../utils/apiResponse.js";
import { ApiError } from "../utils/apiError.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { uploadToCloudinary } from "../utils/cloudinary.js";

import fs from "fs";

// ============================================
// SEND MESSAGE
// ============================================
const sendMessage = asyncHandler(async (req, res) => {
  const { chatId, content, messageType = "text" } = req.body;

  if (!chatId) {
    throw new ApiError(400, "Chat ID is required");
  }

  if (!["text", "image", "voice"].includes(messageType)) {
    throw new ApiError(400, "Invalid message type");
  }

  const chat = await Chat.findOne({ chatId });
  if (!chat) {
    throw new ApiError(404, "Chat not found");
  }

  const isParticipant = chat.participants.some(
    (p) => p._id.toString() === req.user._id.toString()
  );

  if (!isParticipant) {
    throw new ApiError(403, "You are not a participant of this chat");
  }

  let mediaUrls = [];

  try {
    if (req.files && req.files.length > 0) {
      // Upload all files to Cloudinary (NO LOCAL DELETE HERE)
      const uploadPromises = req.files.map(async (file) => {
        const result = await uploadToCloudinary(file.path);
        return result?.secure_url;
      });

      mediaUrls = await Promise.all(uploadPromises);
    }

    if (!content && mediaUrls.length === 0) {
      throw new ApiError(400, "Message must have either content or media");
    }

    const message = await Message.create({
      chatId: chat._id,
      senderId: req.user._id,
      content: content || "",
      media: mediaUrls,
      messageType,
      isRead: false,
    });

    chat.lastMessage =
      messageType === "text"
        ? content
        : messageType === "image"
        ? "📷 Image"
        : "🎤 Voice message";

    chat.lastMessageAt = new Date();
    await chat.save();

    const populatedMessage = await Message.findById(message._id).populate({
      path: "senderId",
      select: "fullName username email profileImage",
    });

    return res.status(201).json(
      new ApiResponse(
        201,
        {
          messageId: populatedMessage.messageId,
          chatId: chat.chatId,
          sender: {
            _id: populatedMessage.senderId._id,
            fullName: populatedMessage.senderId.fullName,
            profileImage: populatedMessage.senderId.profileImage,
          },
          content: populatedMessage.content,
          media: populatedMessage.media,
          messageType: populatedMessage.messageType,
          isRead: populatedMessage.isRead,
          createdAt: populatedMessage.createdAt,
        },
        "Message sent successfully"
      )
    );
  } catch (error) {
    // Only cleanup if multer saved something AND cloudinary didn't delete it
    if (req.files && req.files.length > 0) {
      req.files.forEach((file) => {
        if (fs.existsSync(file.path)) {
          fs.unlinkSync(file.path);
        }
      });
    }
    throw error;
  }
});


// ============================================
// MARK MESSAGES AS READ
// ============================================
const markMessagesAsRead = asyncHandler(async (req, res) => {
  const { chatId } = req.params;

  // Find chat
  const chat = await Chat.findOne({ chatId });
  if (!chat) {
    throw new ApiError(404, "Chat not found");
  }

  // Verify user is a participant
  const isParticipant = chat.participants.some(
    (p) => p._id.toString() === req.user._id.toString()
  );

  if (!isParticipant) {
    throw new ApiError(403, "You are not a participant of this chat");
  }

  // Mark all unread messages (sent by other participant) as read
  const result = await Message.updateMany(
    {
      chatId: chat._id,
      senderId: { $ne: req.user._id },
      isRead: false,
    },
    { isRead: true }
  );

  return res
    .status(200)
    .json(
      new ApiResponse(
        200,
        { markedAsRead: result.modifiedCount },
        "Messages marked as read"
      )
    );
});

export { sendMessage, markMessagesAsRead };