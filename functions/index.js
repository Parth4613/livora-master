/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onCall} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");

// Initialize Firebase Admin
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();
const rtdb = admin.database(); // For Realtime Database operations

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// Callable function to send chat notifications directly without saving to Firestore
exports.sendChatNotification = onCall(
    {maxInstances: 10},
    async (request) => {
      try {
        const {receiverId, senderId, senderName, message, chatRoomId} = request.data;

        // Validate required parameters
        if (!receiverId || !senderId || !senderName || !message || !chatRoomId) {
          throw new Error("Missing required parameters: receiverId, senderId, " +
                    "senderName, message, chatRoomId");
        }

        logger.info(`Sending notification to ${receiverId} from ${senderName}`);

        // Get the receiver's data from Firestore
        const receiverDoc = await db.collection("users").doc(receiverId).get();

        if (!receiverDoc.exists) {
          logger.info(`Receiver ${receiverId} not found`);
          return {success: false, error: "Receiver not found"};
        }

        const receiverData = receiverDoc.data();

        // Check if receiver is currently in a chat with the sender
        if (receiverData.isOnline && receiverData.currentChatRoom) {
          const currentChatRoom = receiverData.currentChatRoom;
          if (currentChatRoom.includes(senderId)) {
            logger.info(`Receiver ${receiverId} is currently in chat with ` +
                        `${senderId}, skipping notification`);
            return {
              success: true,
              skipped: true,
              reason: "User is in chat with sender",
            };
          }
        }

        const fcmToken = receiverData.fcmToken;

        if (!fcmToken) {
          logger.info(`No FCM token found for receiver ${receiverId}`);
          return {success: false, error: "Receiver has no FCM token"};
        }

        // Prepare the notification message
        const notificationMessage = {
          token: fcmToken,
          notification: {
            title: senderName,
            body: message,
          },
          data: {
            type: "chat_message",
            senderId: senderId,
            senderName: senderName,
            chatRoomId: chatRoomId,
            message: message,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            notification: {
              channelId: "chat_notifications",
              priority: "high",
              defaultSound: true,
              defaultVibrateTimings: true,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        // Send the notification
        const response = await messaging.send(notificationMessage);
        logger.info(`Successfully sent notification: ${response}`);

        return {success: true, messageId: response};
      } catch (error) {
        logger.error("Error sending notification:", error);
        throw new Error(`Failed to send notification: ${error.message}`);
      }
    },
);

// Cloud Function to delete chat messages after 7 days from Realtime Database
// Runs every day at 12:15 AM
exports.deleteOldChatMessages = onSchedule(
    {
      schedule: "15 0 * * *", // Cron expression: 15 minutes past midnight
      timeZone: "UTC",
      maxInstances: 1,
    },
    async (event) => {
      try {
        logger.info("Starting cleanup of old chat messages...");

        const cutoffTime = Date.now() - (7 * 24 * 60 * 60 * 1000); // 7 days ago
        let deletedCount = 0;

        // Get all chat rooms from Realtime Database
        const chatRoomsSnapshot = await rtdb.ref("chatRooms").once("value");
        const chatRooms = chatRoomsSnapshot.val();

        if (!chatRooms) {
          logger.info("No chat rooms found");
          return;
        }

        // Process each chat room
        for (const [roomId, roomData] of Object.entries(chatRooms)) {
          if (roomData.messages) {
            const messagesToDelete = [];

            // Check each message in the room
            for (const [messageId, messageData] of Object.entries(roomData.messages)) {
              if (messageData.timestamp && messageData.timestamp < cutoffTime) {
                messagesToDelete.push(messageId);
              }
            }

            // Delete old messages in batches
            if (messagesToDelete.length > 0) {
              const updates = {};
              messagesToDelete.forEach((messageId) => {
                updates[`chatRooms/${roomId}/messages/${messageId}`] = null;
              });

              await rtdb.ref().update(updates);
              deletedCount += messagesToDelete.length;

              logger.info(`Deleted ${messagesToDelete.length} old messages ` +
                            `from room ${roomId}`);
            }
          }
        }

        logger.info(`Chat message cleanup completed. Total messages deleted: ` +
                `${deletedCount}`);
      } catch (error) {
        logger.error("Error during chat message cleanup:", error);
        throw error;
      }
    },
);

// Cloud Function to delete expired listings after 24 hours of expiration
// Runs every hour to check for expired listings
exports.deleteExpiredListings = onSchedule(
    {
      schedule: "15 0 * * *", // Cron expression: 12:15 AM UTC
      timeZone: "UTC",
      maxInstances: 1,
    },
    async (event) => {
      try {
        logger.info("Starting cleanup of expired listings...");

        const cutoffTime = new Date();
        cutoffTime.setHours(cutoffTime.getHours() - 24); // 24 hours ago

        // Query Firestore for expired listings
        const expiredListingsSnapshot = await db
            .collection("listings")
            .where("expirationDate", "<", cutoffTime)
            .get();

        if (expiredListingsSnapshot.empty) {
          logger.info("No expired listings found");
          return;
        }

        // Delete expired listings in batches
        const batchSize = 500; // Firestore batch limit
        const batches = [];

        for (let i = 0; i < expiredListingsSnapshot.docs.length; i += batchSize) {
          const batch = db.batch();
          const batchDocs = expiredListingsSnapshot.docs.slice(i, i + batchSize);

          batchDocs.forEach((doc) => {
            batch.delete(doc.ref);
          });

          batches.push(batch);
        }

        // Execute all batches
        for (const batch of batches) {
          await batch.commit();
        }

        logger.info(`Expired listings cleanup completed. Total listings deleted: ` +
                `${expiredListingsSnapshot.docs.length}`);
      } catch (error) {
        logger.error("Error during expired listings cleanup:", error);
        throw error;
      }
    },
);


