import { Category } from "../models/category.model.js";
import { ApiError } from "../utils/apiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { v4 as uuidv4 } from "uuid";

// ============================================
// CATEGORY CONTROLLERS
// ============================================

/**
 * @desc    Create a new category
 * @route   POST /api/v1/categories
 * @access  Private (Admin only - add verifyAdmin middleware later)
 */
const createCategory = asyncHandler(async (req, res) => {
  const { name, description, icon } = req.body;

  if (!name || !description) {
    throw new ApiError(400, "Name and description are required");
  }

  // Check if category already exists
  const existingCategory = await Category.findOne({ name: name.toLowerCase() });

  if (existingCategory) {
    throw new ApiError(409, "Category with this name already exists");
  }

  // Create category
  const category = await Category.create({
    categoryId: uuidv4(),
    name: name.toLowerCase(),
    description,
    icon: icon || "",
  });

  return res
    .status(201)
    .json(new ApiResponse(201, category, "Category created successfully"));
});

/**
 * @desc    Get all categories
 * @route   GET /api/v1/categories
 * @access  Public
 */
const getAllCategories = asyncHandler(async (req, res) => {
  const { isActive } = req.query;

  // Build filter
  const filter = {};
  if (isActive !== undefined) {
    filter.isActive = isActive === "true";
  }

  const categories = await Category.find(filter).sort({ name: 1 });

  return res
    .status(200)
    .json(
      new ApiResponse(200, categories, "Categories fetched successfully")
    );
});

/**
 * @desc    Get single category by ID
 * @route   GET /api/v1/categories/:categoryId
 * @access  Public
 */
const getCategoryById = asyncHandler(async (req, res) => {
  const { categoryId } = req.params;

  const category = await Category.findOne({ categoryId });

  if (!category) {
    throw new ApiError(404, "Category not found");
  }

  return res
    .status(200)
    .json(new ApiResponse(200, category, "Category fetched successfully"));
});

/**
 * @desc    Update category
 * @route   PATCH /api/v1/categories/:categoryId
 * @access  Private (Admin only)
 */
const updateCategory = asyncHandler(async (req, res) => {
  const { categoryId } = req.params;
  const { name, description, icon, isActive } = req.body;

  if (!name && !description && icon === undefined && isActive === undefined) {
    throw new ApiError(400, "At least one field is required to update");
  }

  const category = await Category.findOne({ categoryId });

  if (!category) {
    throw new ApiError(404, "Category not found");
  }

  // Check if new name already exists (if name is being updated)
  if (name && name.toLowerCase() !== category.name) {
    const existingCategory = await Category.findOne({
      name: name.toLowerCase(),
    });
    if (existingCategory) {
      throw new ApiError(409, "Category with this name already exists");
    }
  }

  // Update fields
  if (name) category.name = name.toLowerCase();
  if (description) category.description = description;
  if (icon !== undefined) category.icon = icon;
  if (isActive !== undefined) category.isActive = isActive;

  await category.save();

  return res
    .status(200)
    .json(new ApiResponse(200, category, "Category updated successfully"));
});

/**
 * @desc    Delete category
 * @route   DELETE /api/v1/categories/:categoryId
 * @access  Private (Admin only)
 */
const deleteCategory = asyncHandler(async (req, res) => {
  const { categoryId } = req.params;

  const category = await Category.findOneAndDelete({ categoryId });

  if (!category) {
    throw new ApiError(404, "Category not found");
  }

  return res
    .status(200)
    .json(new ApiResponse(200, {}, "Category deleted successfully"));
});

// ============================================
// EXPORTS
// ============================================

export {
  createCategory,
  getAllCategories,
  getCategoryById,
  updateCategory,
  deleteCategory,
};