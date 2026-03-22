const mongoose = require('mongoose');

const equipmentSchema = new mongoose.Schema({
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  name: {
    type: String,
    required: true,
    trim: true,
  },
  category: {
    type: String,
    enum: ['Camera', 'Lens', 'Lighting', 'Sound', 'Drone', 'Stabilizer', 'Other'],
    required: true,
  },
  description: {
    type: String,
    default: '',
    trim: true,
  },
  condition: {
    type: String,
    enum: ['Excellent', 'Good', 'Fair'],
    required: true,
  },
  availability: {
    type: String,
    enum: ['Available', 'Rented Out', 'Not Available'],
    default: 'Available',
  },
  rentalType: {
    type: String,
    enum: ['Rent', 'Lend', 'Both'],
    required: true,
  },
  pricePerDay: {
    type: Number,
    default: 0,
    min: 0,
  },
  location: {
    type: String,
    default: '',
    trim: true,
  },
}, { timestamps: true });

module.exports = mongoose.model('Equipment', equipmentSchema);
