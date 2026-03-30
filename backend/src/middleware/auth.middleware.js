const jwt = require('jsonwebtoken');
const User = require('../models/user.model');
const admin = require('../config/firebase-admin');

const ensureFirebaseBackedUser = async (decoded) => {
  const firebaseUid = decoded.uid;
  const email = (decoded.email || '').toString().trim().toLowerCase();
  const displayName = (decoded.name || '').toString().trim();

  let user = await User.findOne({ firebaseUid });

  if (!user && email) {
    user = await User.findOne({ email });
    if (user) {
      user.firebaseUid = firebaseUid;
      user.authProvider = 'firebase';
      await user.save();
    }
  }

  if (!user) {
    const safeEmail = email || `${firebaseUid}@filmdin.firebase.local`;
    user = await User.create({
      name: displayName || (safeEmail.includes('@') ? safeEmail.split('@')[0] : 'Filmdin User'),
      email: safeEmail,
      role: 'Director',
      authProvider: 'firebase',
      firebaseUid,
    });
  }

  return user;
};

module.exports = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
      return res.status(401).json({ message: 'No token provided' });
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.userId = decoded.userId;
      return next();
    } catch (_) {
      const decodedFirebase = await admin.auth().verifyIdToken(token);
      const user = await ensureFirebaseBackedUser(decodedFirebase);
      req.userId = user._id.toString();
      req.firebaseUid = decodedFirebase.uid;
      return next();
    }
  } catch (error) {
    return res.status(401).json({ message: 'Invalid token' });
  }
};