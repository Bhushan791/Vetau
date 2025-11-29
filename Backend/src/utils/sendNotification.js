import admin from "firebase-admin";
import { getFirebaseApp } from "../config/firebase.js";
import { Notification } from "../models/notification.model.js";
import { v4 as uuidv4 } from "uuid";

/**
 * Send push notification to a single user and save to database
 * @param {String} fcmToken - User's FCM device token (can be null)
 * @param {Object} notification - { title, body }
 * @param {Object} data - { userId (required), type (required), postId, claimId, chatId, etc. }
 */
export const sendPushNotification = async (fcmToken, notification, data = {}) => {
  try {
    if (!data.userId || !data.type) {
      console.error("⚠️ userId and type are required");
      return null;
    }

    // 1. Save to database FIRST
    const notificationDoc = await Notification.create({
      notificationId: uuidv4(),
      userId: data.userId,
      type: data.type,
      title: notification.title,
      body: notification.body,
      data: data,
      isSent: false,
    });

    // 2. Send FCM if token exists
    if (fcmToken) {
      try {
        const app = getFirebaseApp();
        
        const message = {
          token: fcmToken,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: {
            ...Object.keys(data).reduce((acc, key) => {
              acc[key] = String(data[key]); // Convert all to string for FCM
              return acc;
            }, {}),
            notificationId: notificationDoc.notificationId,
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

        await admin.messaging().send(message);
        
        notificationDoc.isSent = true;
        await notificationDoc.save();
        
        console.log("✅ Notification sent & saved");
      } catch (fcmError) {
        console.error("❌ FCM failed (saved to DB):", fcmError.message);
      }
    } else {
      console.log("⚠️ No FCM token, saved to DB only");
    }

    return notificationDoc;
  } catch (error) {
    console.error("❌ Notification error:", error.message);
    return null;
  }
};

/**
 * Send notification to multiple users (different data for each)
 * @param {Array} users - [{ fcmToken, userId, ...extraData }]
 * @param {Object} notification - { title, body }
 * @param {String} type - Notification type
 */
export const sendMultipleNotifications = async (users, notification, type) => {
  try {
    if (!users || users.length === 0) {
      return null;
    }

    const results = await Promise.all(
      users.map(async (user) => {
        return await sendPushNotification(
          user.fcmToken,
          notification,
          {
            userId: user.userId,
            type: type,
            ...user.extraData, // postId, commentId, etc.
          }
        );
      })
    );

    const successCount = results.filter(Boolean).length;
    console.log(`✅ Sent ${successCount}/${users.length} notifications`);
    
    return results;
  } catch (error) {
    console.error("❌ Multiple notification error:", error.message);
    return null;
  }
};