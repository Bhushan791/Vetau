import { Server } from "socket.io";
import jwt from "jsonwebtoken";
import { User } from "../models/user.model.js";
import { handleChatEvents } from "./chatHandlers.js";

let io;

export const initializeSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"],
      credentials: true,
    },
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  // Authentication middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token?.replace("Bearer ", "");
      
      if (!token) {
        return next(new Error("Authentication required"));
      }

      const decoded = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET);
      const user = await User.findById(decoded._id).select("-password -refreshToken");

      if (!user) {
        return next(new Error("User not found"));
      }

      socket.user = user;
      next();
    } catch (error) {
      return next(new Error("Authentication failed"));
    }
  });

  // Connection handler
  io.on("connection", (socket) => {
    console.log(`✅ User connected: ${socket.user.fullName} (${socket.id})`);

    // Join user's personal room for notifications
    socket.join(socket.user._id.toString());

    // Handle chat events
    handleChatEvents(io, socket);

    // Handle explicit logout
    socket.on("logout", () => {
      console.log(`🚪 User logging out: ${socket.user.fullName}`);
      
      // Leave all chat rooms
      socket.rooms.forEach(room => {
        if (room !== socket.id && room !== socket.user._id.toString()) {
          socket.leave(room);
        }
      });
      
      // Force disconnect
      socket.disconnect(true);
    });

    // Handle disconnect (app close, network loss, etc.)
    socket.on("disconnect", (reason) => {
      console.log(`❌ User disconnected: ${socket.user.fullName} (Reason: ${reason})`);
      
      // Clean up all rooms
      const rooms = Array.from(socket.rooms);
      rooms.forEach(room => {
        if (room !== socket.id) {
          socket.leave(room);
        }
      });
    });

    // Handle connection errors
    socket.on("error", (error) => {
      console.error(`⚠️ Socket error for ${socket.user.fullName}:`, error.message);
    });
  });

  console.log("🔌 Socket.io initialized");
  return io;
};

export const getIO = () => {
  if (!io) throw new Error("Socket.io not initialized");
  return io;
};