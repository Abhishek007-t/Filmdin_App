const mongoose = require('mongoose');

const jobSchema = new mongoose.Schema({
  postedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  title: {
    type: String,
    required: true,
    trim: true,
  },
  jobType: {
    type: String,
    enum: ['Casting Call', 'Crew Required', 'Post Production', 'Equipment', 'Other'],
    required: true,
  },
  projectName: {
    type: String,
    required: true,
    trim: true,
  },
  projectType: {
    type: String,
    enum: ['Feature Film', 'Short Film', 'Web Series', 'Documentary', 'Advertisement', 'Music Video'],
  },
  role: {
    type: String,
    required: true,
  },
  location: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  requirements: {
    type: String,
    default: '',
  },
  compensation: {
    type: String,
    enum: ['Paid', 'Unpaid', 'Negotiable'],
    default: 'Negotiable',
  },
  deadline: {
    type: Date,
  },
  status: {
    type: String,
    enum: ['Open', 'Closed'],
    default: 'Open',
  },
  applicants: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  }],
}, { timestamps: true });

module.exports = mongoose.model('Job', jobSchema);