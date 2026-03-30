const admin = require('firebase-admin');

let initialized = false;

const initializeFirebaseAdmin = () => {
  if (initialized || admin.apps.length > 0) {
    initialized = true;
    return;
  }

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

  if (serviceAccountJson) {
    try {
      const credentials = JSON.parse(serviceAccountJson);
      admin.initializeApp({
        credential: admin.credential.cert(credentials),
      });
      initialized = true;
      return;
    } catch (error) {
      console.error('Invalid FIREBASE_SERVICE_ACCOUNT_JSON:', error.message);
    }
  }

  try {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
    initialized = true;
  } catch (error) {
    console.error('Firebase Admin initialization failed:', error.message);
  }
};

initializeFirebaseAdmin();

module.exports = admin;
