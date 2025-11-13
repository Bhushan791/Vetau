import { Router } from "express";
import {
  createCategory,
  getAllCategories,
  getCategoryById,
  updateCategory,
  deleteCategory,
} from "../controllers/category.controller.js";
import { verifyJWT } from "../middlewares/auth.middleware.js";

const router = Router();

// ============================================
// PUBLIC ROUTES 
// ============================================

/**
 * @route   GET /api/v1/categories
 * @desc    Get all categories (can filter by isActive)
 * @access  Public
 * @query   ?isActive=true
 */
router.route("/").get(getAllCategories);

/**
 * @route   GET /api/v1/categories/:categoryId
 * @desc    Get single category by ID
 * @access  Public
 */
router.route("/:categoryId").get(getCategoryById);

// ============================================
// PROTECTED ROUTES (Admin only - for now using verifyJWT)---->>for now user can do LATER WILL CHANGED BY ADMINVERIFY MIDDLEWARE
// Note: Add verifyAdmin middleware later for production
// ============================================

/**
 * @route   POST /api/v1/categories
 * @desc    Create a new category
 * @access  Private (Admin)
 */
router.route("/").post(verifyJWT, createCategory);

/**
 * @route   PATCH /api/v1/categories/:categoryId
 * @desc    Update category
 * @access  Private (Admin)
 */
router.route("/:categoryId").patch(verifyJWT, updateCategory);

/**
 * @route   DELETE /api/v1/categories/:categoryId
 * @desc    Delete category
 * @access  Private (Admin)
 */
router.route("/:categoryId").delete(verifyJWT, deleteCategory);

export default router;