const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotification = functions.https.onCall(
  async (data, context) => {
    // Require authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in"
      );
    }

    const { token, title, body } = data;

    if (!token || !title || !body) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "token, title, and body are required"
      );
    }

    try {
      await admin.messaging().send({
        token,
        notification: {
          title,
          body,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "custom",
        },
      });

      return {
        success: true,
        message: "Notification sent successfully",
      };
    } catch (error) {
      console.error("Error sending notification:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send notification",
        error.message
      );
    }
  }
);
