const Job = require('../models/job.model');

// Create Job
exports.createJob = async (req, res) => {
  try {
    const {
      title,
      jobType,
      projectName,
      projectType,
      role,
      location,
      description,
      requirements,
      compensation,
      deadline,
    } = req.body;

    const job = await Job.create({
      postedBy: req.userId,
      title,
      jobType,
      projectName,
      projectType,
      role,
      location,
      description,
      requirements,
      compensation,
      deadline,
    });

    const populatedJob = await Job.findById(job._id)
      .populate('postedBy', 'name role profilePhoto');

    res.status(201).json({
      message: 'Job posted successfully',
      job: populatedJob,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get All Jobs
exports.getAllJobs = async (req, res) => {
  try {
    const { jobType, location } = req.query;

    let query = { status: 'Open' };

    if (jobType) {
      query.jobType = jobType;
    }

    if (location) {
      query.location = { $regex: location, $options: 'i' };
    }

    const jobs = await Job.find(query)
      .populate('postedBy', 'name role profilePhoto')
      .sort({ createdAt: -1 });

    res.json({ jobs });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get My Jobs
exports.getMyJobs = async (req, res) => {
  try {
    const jobs = await Job.find({ postedBy: req.userId })
      .sort({ createdAt: -1 });

    res.json({ jobs });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get Job By ID
exports.getJobById = async (req, res) => {
  try {
    const job = await Job.findById(req.params.id)
      .populate('postedBy', 'name role profilePhoto')
      .populate('applicants', 'name role');

    if (!job) {
      return res.status(404).json({ message: 'Job not found' });
    }

    res.json({ job });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Apply to Job
exports.applyToJob = async (req, res) => {
  try {
    const job = await Job.findById(req.params.id);

    if (!job) {
      return res.status(404).json({ message: 'Job not found' });
    }

    if (job.applicants.includes(req.userId)) {
      return res.status(400).json({ message: 'Already applied to this job' });
    }

    job.applicants.push(req.userId);
    await job.save();

    res.json({
      message: 'Applied successfully',
      applicantsCount: job.applicants.length,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Delete Job
exports.deleteJob = async (req, res) => {
  try {
    const job = await Job.findOneAndDelete({
      _id: req.params.id,
      postedBy: req.userId,
    });

    if (!job) {
      return res.status(404).json({ message: 'Job not found' });
    }

    res.json({ message: 'Job deleted successfully' });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Close Job
exports.closeJob = async (req, res) => {
  try {
    const job = await Job.findOneAndUpdate(
      { _id: req.params.id, postedBy: req.userId },
      { status: 'Closed' },
      { new: true }
    );

    if (!job) {
      return res.status(404).json({ message: 'Job not found' });
    }

    res.json({ message: 'Job closed successfully', job });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};