import { Chat } from "../models/chat.model.js";
import { Message } from "../models/message.model.js";
import { ANONYMOUS_PROFILE_PIC } from "../utils/userHelper.js"; 

export const handleChatEvents = (io, socket) => {
  
  // Join chat room
  socket.on("join_chat", async (data) => {
    try {
      const { chatId } = data;
      const chat = await Chat.findOne({ chatId });

      if (!chat) {
        return socket.emit("error", { message: "Chat not found" });
      }

      const isParticipant = chat.participants.some(
        (p) => p.toString() === socket.user._id.toString()
      );

      if (!isParticipant) {
        return socket.emit("error", { message: "Not authorized" });
      }

      socket.join(chatId);
      socket.emit("joined_chat", { chatId });
      
      console.log(`💥 ${socket.user.fullName} joined chat: ${chatId}`);
    } catch (error) {
      socket.emit("error", { message: error.message });
    }
  });

  // Leave chat room
  socket.on("leave_chat", async (data) => {
    try {
      const { chatId } = data;
      socket.leave(chatId);
      socket.emit("left_chat", { chatId });
      console.log(`👋 ${socket.user.fullName} left chat: ${chatId}`);
    } catch (error) {
      socket.emit("error", { message: error.message });
    }
  });

  // Send message (text only via Socket)
  socket.on("send_message", async (data) => {
    try {
      const { chatId, content } = data;

      if (!content) {
        return socket.emit("error", { message: "Content required" });
      }

      const chat = await Chat.findOne({ chatId }).populate({
        path: "postId",
        select: "isAnonymous userId",
      });

      if (!chat) {
        return socket.emit("error", { message: "Chat not found" });
      }

      const isParticipant = chat.participants.some(
        (p) => p.toString() === socket.user._id.toString()
      );

      if (!isParticipant) {
        return socket.emit("error", { message: "Not authorized" });
      }

      // Create message
      const message = await Message.create({
        chatId: chat._id,
        senderId: socket.user._id,
        content,
        messageType: "text",
        isRead: false,
      });

      // Update chat
      chat.lastMessage = content;
      chat.lastMessageAt = new Date();
      await chat.save();

      // Populate sender
      await message.populate({
        path: "senderId",
        select: "fullName username profileImage",
      });

      // ============================================
      // ✅ FORMAT SENDER BASED ON ANONYMOUS STATUS
      // ============================================
      let senderName = message.senderId.fullName;
      let senderProfileImage = message.senderId.profileImage;

      if (
        chat.postId.isAnonymous &&
        chat.postId.userId.toString() === message.senderId._id.toString()
      ) {
        senderName = message.senderId.username || message.senderId.fullName;
        senderProfileImage = ANONYMOUS_PROFILE_PIC;
      }
      // ============================================

      const formattedMessage = {
        messageId: message.messageId,
        chatId: chat.chatId,
        sender: {
          _id: message.senderId._id,
          fullName: senderName,
          profileImage: senderProfileImage,
        },
        content: message.content,
        media: message.media,
        messageType: message.messageType,
        isRead: message.isRead,
        createdAt: message.createdAt,
      };

      // Send to sender (confirmation)
      socket.emit("message_sent", formattedMessage);

      // Broadcast to other user
      socket.to(chatId).emit("new_message", formattedMessage);

      console.log(`💬 Message sent in ${chatId}`);
    } catch (error) {
      socket.emit("error", { message: error.message });
    }
  });

  // Typing indicator
  socket.on("typing", (data) => {
    socket.to(data.chatId).emit("user_typing", {
      chatId: data.chatId,
      userId: socket.user._id,
      fullName: socket.user.fullName,
    });
  });

  socket.on("stop_typing", (data) => {
    socket.to(data.chatId).emit("user_stop_typing", {
      chatId: data.chatId,
    });
  });

  // Cleanup on disconnect - auto leave all chat rooms
  socket.on("disconnecting", () => {
    const chatRooms = Array.from(socket.rooms).filter(
      room => room !== socket.id && room !== socket.user._id.toString()
    );
    
    if (chatRooms.length > 0) {
      console.log(`🧹 Cleaning up ${chatRooms.length} chat rooms for ${socket.user.fullName}`);
    }
  });
};