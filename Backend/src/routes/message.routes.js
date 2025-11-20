import { Router } from "express";
import {
  sendMessage,
  markMessagesAsRead,
} from "../controllers/message.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";
import { chatUpload } from "../middlewares/chatUpload.middleware.js";

const router = Router();

// All routes are protected
router.use(verifyJWT);

// Send message (with optional media upload - max 5 files)
router.post("/", chatUpload.array("media", 5), sendMessage);

// Mark messages as read in a chat
router.patch("/:chatId/read", markMessagesAsRead);

export default router;