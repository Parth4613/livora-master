const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

// Initialize Firebase Admin
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

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
setGlobalOptions({ maxInstances: 10 });

// Cloud Function to send FCM notifications when a notification request is created
exports.sendChatNotification = onDocumentCreated(
  "notification_requests/{requestId}",
  async (event) => {
    try {
      const notificationData = event.data.data();
      
      // Check if this is a chat message notification
      if (notificationData.type !== 'chat_message') {
        logger.info('Not a chat message notification, skipping');
        return null;
      }

      const {
        receiverId,
        senderId,
        senderName,
        message,
        chatRoomId
      } = notificationData;

      logger.info(`Sending notification to ${receiverId} from ${senderName}`);

      // Get the receiver's FCM token from Firestore
      const receiverDoc = await db.collection('users').doc(receiverId).get();
      
      if (!receiverDoc.exists) {
        logger.info(`Receiver ${receiverId} not found`);
        return null;
      }

      const receiverData = receiverDoc.data();
      const fcmToken = receiverData.fcmToken;

      if (!fcmToken) {
        logger.info(`No FCM token found for receiver ${receiverId}`);
        return null;
      }

      // Prepare the notification message
      const notificationMessage = {
        token: fcmToken,
        notification: {
          title: senderName,
          body: message,
        },
        data: {
          type: 'chat_message',
          senderId: senderId,
          senderName: senderName,
          chatRoomId: chatRoomId,
          message: message,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'chat_notifications',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // Send the notification
      const response = await messaging.send(notificationMessage);
      logger.info(`Successfully sent notification: ${response}`);

      // Update the notification request status
      await event.data.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        fcmResponse: response,
      });

      return response;
    } catch (error) {
      logger.error('Error sending notification:', error);
      
      // Update the notification request with error status
      await event.data.ref.update({
        status: 'error',
        error: error.message,
        errorAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      throw error;
    }
  }
);

// Test function to manually send a notification
exports.testNotification = onRequest(
  { maxInstances: 5 },
  async (request, response) => {
    // Enable CORS
    response.set('Access-Control-Allow-Origin', '*');
    response.set('Access-Control-Allow-Methods', 'GET, POST');
    response.set('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method === 'OPTIONS') {
      response.status(204).send('');
      return;
    }

    try {
      const { receiverId, message } = request.body;
      
      if (!receiverId || !message) {
        response.status(400).json({
          error: 'receiverId and message are required'
        });
        return;
      }

      // Get the receiver's FCM token
      const receiverDoc = await db.collection('users').doc(receiverId).get();
      
      if (!receiverDoc.exists) {
        response.status(404).json({
          error: 'Receiver not found'
        });
        return;
      }

      const receiverData = receiverDoc.data();
      const fcmToken = receiverData.fcmToken;

      if (!fcmToken) {
        response.status(400).json({
          error: 'Receiver has no FCM token'
        });
        return;
      }

      // Send test notification
      const notificationMessage = {
        token: fcmToken,
        notification: {
          title: 'Test Notification',
          body: message,
        },
        data: {
          type: 'test',
          message: message,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'chat_notifications',
            priority: 'high',
          },
        },
      };

      const result = await messaging.send(notificationMessage);
      
      response.json({
        success: true,
        messageId: result,
        message: 'Test notification sent successfully'
      });
    } catch (error) {
      logger.error('Error sending test notification:', error);
      response.status(500).json({
        error: error.message
      });
    }
  }
); 