import { Comment } from "../models/comment.model.js";
import { Post } from "../models/post.model.js";
import { ApiError } from "../utils/apiError.js";
import { ApiResponse } from "../utils/apiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";

// ============================================
// ADD COMMENT OR REPLY
// ============================================
const addComment = asyncHandler(async (req, res) => {
  const { postId, content, parentCommentId } = req.body;

  // Validation
  if (!postId) {
    throw new ApiError(400, "Post ID is required");
  }

  if (!content || content.trim().length === 0) {
    throw new ApiError(400, "Comment content is required");
  }

  if (content.length > 500) {
    throw new ApiError(400, "Comment cannot exceed 500 characters");
  }

  // Check if post exists
  const post = await Post.findOne({ postId });
  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  const isPostOwner = post.userId.toString() === req.user._id.toString();

  let parentCommentObjectId = null;
  let rootCommentObjectId = null;

  // Handle reply logic
  if (parentCommentId) {
    const parentComment = await Comment.findOne({ commentId: parentCommentId })
      .populate("postId")
      .populate("userId");

    if (!parentComment) {
      throw new ApiError(404, "Parent comment not found");
    }

    // Check if parent comment belongs to the same post
    if (parentComment.postId._id.toString() !== post._id.toString()) {
      throw new ApiError(400, "Parent comment does not belong to this post");
    }

    // Find the root comment (start of the thread)
    const rootComment = parentComment.rootCommentId
      ? await Comment.findById(parentComment.rootCommentId).populate("userId")
      : parentComment;

    // Authorization Logic:
    // 1. If root comment is by post owner -> Anyone can reply (edge case)
    // 2. Otherwise -> Only post owner and the root commentor can participate
    const isRootCommentByPostOwner = 
      rootComment.userId._id.toString() === post.userId.toString();

    if (!isRootCommentByPostOwner) {
      // Normal case: Only post owner OR root commentor can participate
      const isRootCommentor = 
        rootComment.userId._id.toString() === req.user._id.toString();

      if (!isPostOwner && !isRootCommentor) {
        throw new ApiError(
          403,
          "Only post owner and the original commentor can participate in this conversation"
        );
      }
    }
    // If root comment is by post owner, anyone can reply (no restriction)

    parentCommentObjectId = parentComment._id;
    rootCommentObjectId = rootComment._id;
  }

  // Create comment
  const comment = await Comment.create({
    postId: post._id,
    userId: req.user._id,
    content: content.trim(),
    parentCommentId: parentCommentObjectId,
    rootCommentId: rootCommentObjectId, // null for root comments
  });

  // Increment post's totalComments counter
  post.totalComments = (post.totalComments || 0) + 1;
  await post.save();

  // Populate user details
  const populatedComment = await Comment.findById(comment._id).populate(
    "userId",
    "fullName username profileImage"
  );

  return res
    .status(201)
    .json(
      new ApiResponse(
        201,
        {
          commentId: populatedComment.commentId,
          postId: post.postId,
          user: {
            _id: populatedComment.userId._id,
            fullName: populatedComment.userId.fullName,
            username: populatedComment.userId.username,
            profileImage: populatedComment.userId.profileImage,
          },
          content: populatedComment.content,
          parentCommentId: populatedComment.parentCommentId,
          isEdited: populatedComment.isEdited,
          createdAt: populatedComment.createdAt,
        },
        parentCommentId ? "Reply added successfully" : "Comment added successfully"
      )
    );
});

// ============================================
// GET COMMENTS BY POST (Nested Structure)
// ============================================
const getCommentsByPost = asyncHandler(async (req, res) => {
  const { postId } = req.params;
  const { page = 1, limit = 20 } = req.query;
  const skip = (page - 1) * limit;

  // Check if post exists
  const post = await Post.findOne({ postId });
  if (!post) {
    throw new ApiError(404, "Post not found");
  }

  // Get root comments (parentCommentId = null)
  const rootComments = await Comment.find({
    postId: post._id,
    parentCommentId: null,
  })
    .populate("userId", "fullName username profileImage")
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

  // Get total count of root comments
  const totalComments = await Comment.countDocuments({
    postId: post._id,
    parentCommentId: null,
  });

  // Helper function to build nested replies recursively
  const buildNestedReplies = async (commentId) => {
    const replies = await Comment.find({
      parentCommentId: commentId,
    })
      .populate("userId", "fullName username profileImage")
      .sort({ createdAt: 1 }); // Oldest first (chronological)

    const nestedReplies = [];
    
    for (const reply of replies) {
      const isReplyPostOwner = 
        reply.userId._id.toString() === post.userId.toString();
      const isReplyCurrentUser = 
        reply.userId._id.toString() === req.user._id.toString();

      const childReplies = await buildNestedReplies(reply._id);

      nestedReplies.push({
        commentId: reply.commentId,
        user: {
          _id: reply.userId._id,
          fullName: reply.userId.fullName,
          username: reply.userId.username,
          profileImage: reply.userId.profileImage,
          isPostOwner: isReplyPostOwner,
        },
        content: reply.content,
        isEdited: reply.isEdited,
        createdAt: reply.createdAt,
        canEdit: isReplyCurrentUser,
        canDelete: isReplyCurrentUser,
        replies: childReplies,
      });
    }

    return nestedReplies;
  };

  // For each root comment, fetch all nested replies
  const commentsWithReplies = await Promise.all(
    rootComments.map(async (comment) => {
      const isPostOwner =
        comment.userId._id.toString() === post.userId.toString();
      const isCurrentUser =
        comment.userId._id.toString() === req.user._id.toString();

      // Determine who can reply based on thread rules
      let canReply = false;
      if (isPostOwner) {
        // If root comment is by post owner, anyone can reply
        canReply = true;
      } else {
        // Normal case: Only post owner or the root commentor can reply
        canReply = isCurrentUser || post.userId.toString() === req.user._id.toString();
      }

      const replies = await buildNestedReplies(comment._id);

      return {
        commentId: comment.commentId,
        user: {
          _id: comment.userId._id,
          fullName: comment.userId.fullName,
          username: comment.userId.username,
          profileImage: comment.userId.profileImage,
          isPostOwner,
        },
        content: comment.content,
        isEdited: comment.isEdited,
        createdAt: comment.createdAt,
        canReply,
        canEdit: isCurrentUser,
        canDelete: isCurrentUser,
        replies,
      };
    })
  );

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        comments: commentsWithReplies,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalComments / limit),
          totalComments,
          hasMore: skip + rootComments.length < totalComments,
        },
      },
      "Comments fetched successfully"
    )
  );
});

// ============================================
// UPDATE COMMENT
// ============================================
const updateComment = asyncHandler(async (req, res) => {
  const { commentId } = req.params;
  const { content } = req.body;

  // Validation
  if (!content || content.trim().length === 0) {
    throw new ApiError(400, "Comment content is required");
  }

  if (content.length > 500) {
    throw new ApiError(400, "Comment cannot exceed 500 characters");
  }

  // Find comment
  const comment = await Comment.findOne({ commentId });
  if (!comment) {
    throw new ApiError(404, "Comment not found");
  }

  // Check ownership
  if (comment.userId.toString() !== req.user._id.toString()) {
    throw new ApiError(403, "You can only edit your own comments");
  }

  // Update comment
  comment.content = content.trim();
  comment.isEdited = true;
  await comment.save();

  return res
    .status(200)
    .json(
      new ApiResponse(
        200,
        {
          commentId: comment.commentId,
          content: comment.content,
          isEdited: comment.isEdited,
          updatedAt: comment.updatedAt,
        },
        "Comment updated successfully"
      )
    );
});

// ============================================
// DELETE COMMENT
// ============================================
const deleteComment = asyncHandler(async (req, res) => {
  const { commentId } = req.params;

  // Find comment
  const comment = await Comment.findOne({ commentId });
  if (!comment) {
    throw new ApiError(404, "Comment not found");
  }

  // Check ownership
  if (comment.userId.toString() !== req.user._id.toString()) {
    throw new ApiError(403, "You can only delete your own comments");
  }

  // Get post for updating counter
  const post = await Post.findById(comment.postId);

  // Recursively delete all nested replies
  const deleteRecursive = async (commentId) => {
    const replies = await Comment.find({ parentCommentId: commentId });
    let count = 0;
    
    for (const reply of replies) {
      count += await deleteRecursive(reply._id);
    }
    
    await Comment.deleteOne({ _id: commentId });
    return count + 1;
  };

  const totalDeleted = await deleteRecursive(comment._id);

  // Decrement post's totalComments counter
  post.totalComments = Math.max((post.totalComments || 0) - totalDeleted, 0);
  await post.save();

  return res
    .status(200)
    .json(
      new ApiResponse(
        200,
        {
          deletedCommentId: commentId,
          totalDeleted: totalDeleted - 1, // Exclude the comment itself
        },
        "Comment deleted successfully"
      )
    );
});

export { addComment, getCommentsByPost, updateComment, deleteComment };