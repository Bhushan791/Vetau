import admin from "firebase-admin";

let firebaseApp;

export const initializeFirebase = () => {
  try {
    if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_CLIENT_EMAIL || !process.env.FIREBASE_PRIVATE_KEY) {
      throw new Error("Firebase environment variables are not set");
    }

    // Initialize Firebase app using environment variables
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        // Replace literal \n with actual newlines
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n"),
      }),
    });

    console.log("🔥 Firebase initialized successfully");
  } catch (error) {
    console.error("❌ Firebase initialization failed:", error.message);
    console.error("Full error:", error);
  }
};

export const getFirebaseApp = () => {
  if (!firebaseApp) {
    throw new Error("Firebase not initialized");
  }
  return firebaseApp;
};