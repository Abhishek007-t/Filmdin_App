const Credit = require('../models/credit.model');

// Add Credit
exports.addCredit = async (req, res) => {
  try {
    const { projectName, projectType, role, year, description } = req.body;

    const credit = await Credit.create({
      user: req.userId,
      projectName,
      projectType,
      role,
      year,
      description,
    });

    res.status(201).json({
      message: 'Credit added successfully',
      credit,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get My Credits
exports.getMyCredits = async (req, res) => {
  try {
    const credits = await Credit.find({ user: req.userId })
      .sort({ year: -1 });

    res.json({ credits });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get Credits by User ID
exports.getUserCredits = async (req, res) => {
  try {
    const credits = await Credit.find({ user: req.params.userId })
      .sort({ year: -1 });

    res.json({ credits });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Delete Credit
exports.deleteCredit = async (req, res) => {
  try {
    const credit = await Credit.findOneAndDelete({
      _id: req.params.id,
      user: req.userId,
    });

    if (!credit) {
      return res.status(404).json({ message: 'Credit not found' });
    }

    res.json({ message: 'Credit deleted successfully' });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};
