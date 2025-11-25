import * as turf from "@turf/turf";

/**
 * Calculate distance between two points using TURF.js
 * @param {Number} userLat - User's latitude
 * @param {Number} userLng - User's longitude
 * @param {Array} postCoordinates - Post's [lng, lat]
 * @returns {Number} Distance in kilometers
 */
export const calculateDistance = (userLat, userLng, postCoordinates) => {
  if (!postCoordinates || postCoordinates.length !== 2) {
    return null; // Post has no coordinates (typed manually)
  }

  const userPoint = turf.point([userLng, userLat]); // [lng, lat]
  const postPoint = turf.point(postCoordinates); // [lng, lat]

  const distance = turf.distance(userPoint, postPoint, { units: "kilometers" });
  return parseFloat(distance.toFixed(2)); // Round to 2 decimals
};

/**
 * Filter posts within radius
 * @param {Array} posts - Array of posts
 * @param {Number} userLat - User's latitude
 * @param {Number} userLng - User's longitude
 * @param {Number} radius - Radius in kilometers (default 7km)
 * @returns {Array} Filtered posts with distance
 */
export const filterPostsByDistance = (
  posts,
  userLat,
  userLng,
  radius = 7
) => {
  const nearbyPosts = [];

  posts.forEach((post) => {
    // Skip posts without coordinates
    if (!post.location.coordinates || post.location.coordinates.length !== 2) {
      return;
    }

    const distance = calculateDistance(
      userLat,
      userLng,
      post.location.coordinates
    );

    if (distance !== null && distance <= radius) {
      const postObj = post.toObject ? post.toObject() : post;
      postObj.distance = distance;
      nearbyPosts.push(postObj);
    }
  });

  // Sort by distance (nearest first)
  return nearbyPosts.sort((a, b) => a.distance - b.distance);
};