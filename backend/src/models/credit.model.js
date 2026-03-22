const mongoose = require('mongoose');

const creditSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  projectName: {
    type: String,
    required: true,
    trim: true,
  },
  projectType: {
    type: String,
    enum: [
      'Feature Film',
      'Short Film',
      'Web Series',
      'Documentary',
      'Advertisement',
      'Music Video',
    ],
    required: true,
  },
  role: {
    type: String,
    required: true,
  },
  year: {
    type: Number,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  posterUrl: {
    type: String,
    default: '',
  },
}, { timestamps: true });

module.exports = mongoose.model('Credit', creditSchema);