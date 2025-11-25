// ============================================
// USER HELPER UTILITY
// Centralized logic for handling anonymous user data
// ============================================

// Default anonymous profile picture URL
const ANONYMOUS_PROFILE_PIC = "https://res.cloudinary.com/dq0mlhw2c/image/upload/v1764092757/icon-7797704_640_rftvtx.png";

/**
 * Format user data for anonymous content
 * @param {Object} user - User object with fullName, username, profileImage
 * @param {Boolean} isAnonymous - Whether the content is anonymous
 * @returns {Object} - Formatted user object
 */
export const formatUserForAnonymous = (user, isAnonymous) => {
  if (!isAnonymous) {
    // Return full user data if not anonymous
    return user;
  }

  // Return only username and anonymous profile pic
  return {
    username: user.username,
    profileImage: ANONYMOUS_PROFILE_PIC,
  };
};

/**
 * Format post with anonymous user handling
 * Used in post controller to hide user info for anonymous posts
 * @param {Object} post - Post object
 * @returns {Object} - Formatted post object
 */
export const formatPostWithAnonymous = (post) => {
  const postObj = post.toObject ? post.toObject() : post;
  
  if (postObj.isAnonymous && postObj.userId) {
    postObj.userId = formatUserForAnonymous(postObj.userId, true);
  }
  
  return postObj;
};

/**
 * Format comment with anonymous user handling
 * Used in comment controller
 * @param {Object} comment - Comment object
 * @param {Object} post - Post object (to check if post is anonymous)
 * @param {String} currentUserId - Current logged-in user's ID
 * @returns {Object} - Formatted comment object
 */
export const formatCommentWithAnonymous = (comment, post, currentUserId) => {
  const commentObj = comment.toObject ? comment.toObject() : comment;
  
  // Check if commenter is the post owner AND post is anonymous
  const isCommentByAnonymousPostOwner = 
    post.isAnonymous && 
    post.userId.toString() === commentObj.userId._id.toString();

  if (isCommentByAnonymousPostOwner) {
    commentObj.userId = formatUserForAnonymous(commentObj.userId, true);
  }

  return commentObj;
};

/**
 * Format chat participant with anonymous handling
 * Used in chat controller
 * @param {Object} participant - Participant user object
 * @param {Object} post - Post object (to check if post is anonymous)
 * @returns {Object} - Formatted participant object
 */
export const formatChatParticipantForAnonymous = (participant, post) => {
  // If post was anonymous and this participant is the post owner
  if (post.isAnonymous && post.userId.toString() === participant._id.toString()) {
    return {
      _id: participant._id,
      fullName: participant.username || participant.fullName,
      email: participant.email,
      profileImage: ANONYMOUS_PROFILE_PIC,
    };
  }

  // Return normal participant data
  return {
    _id: participant._id,
    fullName: participant.fullName,
    email: participant.email,
    profileImage: participant.profileImage,
  };
};

/**
 * Format message sender with anonymous handling
 * Used in message controller
 * @param {Object} sender - Sender user object
 * @param {Object} post - Post object (to check if post is anonymous)
 * @returns {Object} - Formatted sender object
 */
export const formatMessageSenderForAnonymous = (sender, post) => {
  // If post was anonymous and sender is the post owner
  if (post.isAnonymous && post.userId.toString() === sender._id.toString()) {
    return {
      _id: sender._id,
      fullName: sender.username || sender.fullName,
      profileImage: ANONYMOUS_PROFILE_PIC,
    };
  }

  // Return normal sender data
  return {
    _id: sender._id,
    fullName: sender.fullName,
    profileImage: sender.profileImage,
  };
};

export { ANONYMOUS_PROFILE_PIC };