import { Chat } from "../models/chat.model.js";
import { Message } from "../models/message.model.js";
import { Post } from "../models/post.model.js";
import { ApiError } from "../utils/apiError.js";
import { ApiResponse } from "../utils/apiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ANONYMOUS_PROFILE_PIC } from "../utils/userHelper.js";
// ============================================
// GET MY CHATS
// ============================================
const getMyChats = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  const skip = (page - 1) * limit;

  // Find all chats where current user is a participant
  const chats = await Chat.find({
    participants: req.user._id,
    isActive: true,
  })
    .populate({
      path: "participants",
      select: "fullName username email profileImage",
    })
    .populate({
      path: "postId",
      select: "postId type itemName images isAnonymous userId",
    })
    .sort({ lastMessageAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

  // Get total count
  const totalChats = await Chat.countDocuments({
    participants: req.user._id,
    isActive: true,
  });

  // Format response with anonymous username handling
const formattedChats = chats.map((chat) => {
  const otherParticipant = chat.participants.find(
    (p) => p._id.toString() !== req.user._id.toString()
  );

  // Check if post was anonymous and other participant is the post owner
  let displayName = otherParticipant.fullName;
  let displayProfileImage = otherParticipant.profileImage; //  NEW

  if (
    chat.postId.isAnonymous &&
    chat.postId.userId.toString() === otherParticipant._id.toString()
  ) {
    displayName = otherParticipant.username || otherParticipant.fullName;
    displayProfileImage = ANONYMOUS_PROFILE_PIC; //  ANONYMOUS PIC
  }

  return {
    chatId: chat.chatId,
    postId: chat.postId.postId,
    postType: chat.postId.type,
    itemName: chat.postId.itemName,
    postImage: chat.postId.images?.[0] || null,
    otherParticipant: {
      fullName: displayName,
      email: otherParticipant.email,
      profileImage: displayProfileImage, //  USE ANONYMOUS PIC
    },
    lastMessage: chat.lastMessage,
    lastMessageAt: chat.lastMessageAt,
    createdAt: chat.createdAt,
  };
});
  return res.status(200).json(
    new ApiResponse(
      200,
      {
        chats: formattedChats,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalChats / limit),
          totalChats,
          hasMore: skip + chats.length < totalChats,
        },
      },
      "Chats fetched successfully"
    )
  );
});

// ============================================
// GET CHAT BY ID
// ============================================
const getChatById = asyncHandler(async (req, res) => {
  const { chatId } = req.params;

  // Find chat
  const chat = await Chat.findOne({ chatId })
    .populate({
      path: "participants",
      select: "fullName username email profileImage",
    })
    .populate({
      path: "postId",
      select:
        "postId type itemName description location images rewardAmount category status isAnonymous userId",
    })
    .populate({
      path: "claimId",
      select: "claimType message status",
    });

  if (!chat) {
    throw new ApiError(404, "Chat not found");
  }

  // Check if current user is a participant
  const isParticipant = chat.participants.some(
    (p) => p._id.toString() === req.user._id.toString()
  );

  if (!isParticipant) {
    throw new ApiError(403, "You are not a participant of this chat");
  }

  // Format participants with anonymous username handling
const formattedParticipants = chat.participants.map((participant) => {
  let displayName = participant.fullName;
  let displayProfileImage = participant.profileImage; //  NEW

  // If post was anonymous and this participant is the post owner
  if (
    chat.postId.isAnonymous &&
    chat.postId.userId.toString() === participant._id.toString()
  ) {
    displayName = participant.username || participant.fullName;
    displayProfileImage = ANONYMOUS_PROFILE_PIC; //  ANONYMOUS PIC
  }

  return {
    _id: participant._id,
    fullName: displayName,
    email: participant.email,
    profileImage: displayProfileImage, // USE ANONYMOUS PIC
  };
});

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        chatId: chat.chatId,
        post: chat.postId,
        claim: chat.claimId,
        participants: formattedParticipants,
        lastMessage: chat.lastMessage,
        lastMessageAt: chat.lastMessageAt,
        isActive: chat.isActive,
        createdAt: chat.createdAt,
      },
      "Chat details fetched successfully"
    )
  );
});

// ============================================
// GET CHAT MESSAGES
// ============================================
const getChatMessages = asyncHandler(async (req, res) => {
  const { chatId } = req.params;
  const { page = 1, limit = 50 } = req.query;
  const skip = (page - 1) * limit;

  // Find chat and verify participant
  const chat = await Chat.findOne({ chatId }).populate({
    path: "postId",
    select: "isAnonymous userId",
  });

  if (!chat) {
    throw new ApiError(404, "Chat not found");
  }

  // Check if current user is a participant
  const isParticipant = chat.participants.some(
    (p) => p._id.toString() === req.user._id.toString()
  );

  if (!isParticipant) {
    throw new ApiError(403, "You are not a participant of this chat");
  }

  // Get messages
  const messages = await Message.find({ chatId: chat._id })
    .populate({
      path: "senderId",
      select: "fullName username email profileImage",
    })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

  // Get total count
  const totalMessages = await Message.countDocuments({ chatId: chat._id });

  // Mark unread messages as read (only messages sent by other participant)
  await Message.updateMany(
    {
      chatId: chat._id,
      senderId: { $ne: req.user._id },
      isRead: false,
    },
    { isRead: true }
  );

  // Format messages with anonymous username handling
const formattedMessages = messages.map((msg) => {
  let senderName = msg.senderId.fullName;
  let senderProfileImage = msg.senderId.profileImage; //  NEW

  // If post was anonymous and sender is the post owner
  if (
    chat.postId.isAnonymous &&
    chat.postId.userId.toString() === msg.senderId._id.toString()
  ) {
    senderName = msg.senderId.username || msg.senderId.fullName;
    senderProfileImage = ANONYMOUS_PROFILE_PIC; //  ANONYMOUS PIC
  }

  return {
    messageId: msg.messageId,
    sender: {
      _id: msg.senderId._id,
      fullName: senderName,
      profileImage: senderProfileImage, // USE ANONYMOUS PIC
    },
    content: msg.content,
    media: msg.media,
    messageType: msg.messageType,
    isRead: msg.isRead,
    createdAt: msg.createdAt,
    isMine: msg.senderId._id.toString() === req.user._id.toString(),
  };
});

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        messages: formattedMessages.reverse(), // Oldest first for display
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalMessages / limit),
          totalMessages,
          hasMore: skip + messages.length < totalMessages,
        },
      },
      "Messages fetched successfully"
    )
  );
});

export { getMyChats, getChatById, getChatMessages };