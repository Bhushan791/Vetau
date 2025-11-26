import admin from "firebase-admin";
import { getFirebaseApp } from "../config/firebase.js";

/**
 * Send push notification to a user
 * @param {String} fcmToken - User's FCM device token
 * @param {Object} notification - { title, body }
 * @param {Object} data - Additional data payload
 */
export const sendPushNotification = async (fcmToken, notification, data = {}) => {
  try {
    if (!fcmToken) {
      console.log("⚠️ No FCM token provided");
      return null;
    }

    const app = getFirebaseApp();
    
    const message = {
      token: fcmToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        ...data,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log("✅ Notification sent:", response);
    return response;
  } catch (error) {
    console.error("❌ Notification error:", error.message);
    return null;
  }
};

/**
 * Send notification to multiple users
 */
export const sendMultipleNotifications = async (tokens, notification, data = {}) => {
  try {
    if (!tokens || tokens.length === 0) {
      return null;
    }

    const app = getFirebaseApp();

    const message = {
      tokens: tokens.filter(Boolean), // Remove null/undefined
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        ...data,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`✅ Sent ${response.successCount}/${tokens.length} notifications`);
    return response;
  } catch (error) {
    console.error("❌ Multiple notification error:", error.message);
    return null;
  }
};