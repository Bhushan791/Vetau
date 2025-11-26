import { Router } from "express";
import {
  savePost,
  unsavePost,
  getMySavedPosts,
  checkIfPostSaved,
} from "../controllers/savedPost.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";

const router = Router();

// All routes require authentication
router.use(verifyJWT);

// Save/Unsave routes
router.route("/save/:postId").post(savePost);
router.route("/unsave/:postId").delete(unsavePost);

// Get saved posts
router.route("/my-saved-posts").get(getMySavedPosts);

// Check if post is saved
router.route("/check/:postId").get(checkIfPostSaved);

export default router;