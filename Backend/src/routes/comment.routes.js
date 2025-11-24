import { Router } from "express";
import {
  addComment,
  getCommentsByPost,
  updateComment,
  deleteComment,
} from "../controllers/comment.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";

const router = Router();

// All routes are protected
router.use(verifyJWT);

// Add comment or reply (text only)
router.post("/", addComment);

// Get all comments for a post
router.get("/post/:postId", getCommentsByPost);

// Update comment (text only)
router.patch("/:commentId", updateComment);

// Delete comment
router.delete("/:commentId", deleteComment);

export default router;