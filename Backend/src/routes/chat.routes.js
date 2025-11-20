import { Router } from "express";
import {
  getMyChats,
  getChatById,
  getChatMessages,
} from "../controllers/chat.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";

const router = Router();

// All routes are protected
router.use(verifyJWT);

// Get all my chats
router.get("/", getMyChats);

// Get specific chat details
router.get("/:chatId", getChatById);

// Get all messages in a chat
router.get("/:chatId/messages", getChatMessages);

export default router;