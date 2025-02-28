/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.deleteUserByUid = functions.https.onCall(async (data, context) => {
  // Example: only allow calls from users with an "admin" custom claim
  // if (!context.auth.token.isAdmin) {
  //   throw new functions.https.HttpsError("permission-denied", "Only admins can delete users.");
  // }

  const uid = data.uid;
  if (!uid) {
    throw new functions.https.HttpsError("invalid-argument", "No uid provided.");
  }

  try {
    // 1) Delete user from Firebase Auth
    await admin.auth().deleteUser(uid);

    // 2) Delete user doc in Firestore if desired
    await admin.firestore().collection("users").doc(uid).delete();

    return {success: true};
  } catch (err) {
    console.error("Delete user error:", err);
    throw new functions.https.HttpsError("unknown", err.message);
  }
});


exports.updateUserAuth = functions.https.onCall(async (data, context) => {
  // Check that the function is called by an authenticated admin user (customize as needed)
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
    );
  }

  // You may want to check custom claims for admin privileges
  // For example:
  // if (!context.auth.token.admin) {
  //   throw new functions.https.HttpsError("permission-denied", "Insufficient permissions.");
  // }

  // Get parameters from the client
  const uid = data.uid;
  const newEmail = data.newEmail;
  const newPassword = data.newPassword;

  try {
    // Update the user using the Admin SDK
    const userRecord = await admin.auth().updateUser(uid, {
      email: newEmail,
      password: newPassword,
    });
    return {message: "User updated successfully", user: userRecord.toJSON()};
  } catch (error) {
    throw new functions.https.HttpsError("unknown", error.message, error);
  }
});
