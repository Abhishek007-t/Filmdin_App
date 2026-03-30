const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  password: {
    type: String,
    required() {
      return this.authProvider !== 'firebase';
    },
    minlength: 6,
    default: '',
  },
  authProvider: {
    type: String,
    enum: ['custom', 'firebase'],
    default: 'custom',
  },
  firebaseUid: {
    type: String,
    unique: true,
    sparse: true,
    default: null,
  },
  role: {
    type: String,
    enum: ['Director','Actor','Cinematographer','Producer',
           'Editor','Sound Designer','Screenwriter',
           'Costume Designer','Crew Member'],
    default: 'Director',
  },
  bio: { type: String, default: '' },
  location: { type: String, default: '' },
  profilePhoto: { type: String, default: '' },
  resetPasswordToken: { type: String, default: null },
  resetPasswordExpires: { type: Date, default: null },
  followers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  following: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);