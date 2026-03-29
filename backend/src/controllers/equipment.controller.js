const Equipment = require('../models/equipment.model');

// Create Equipment Listing
exports.listEquipment = async (req, res) => {
  try {
    const {
      name,
      category,
      description,
      condition,
      availability,
      rentalType,
      pricePerDay,
      location,
    } = req.body;

    if (!name || !category || !condition || !rentalType) {
      return res.status(400).json({
        message: 'Name, category, condition and rental type are required',
      });
    }

    const equipment = await Equipment.create({
      owner: req.userId,
      name,
      category,
      description,
      condition,
      availability,
      rentalType,
      pricePerDay: Number(pricePerDay) || 0,
      location,
    });

    const populatedEquipment = await Equipment.findById(equipment._id)
      .populate('owner', 'name role email');

    return res.status(201).json({
      message: 'Equipment listed successfully',
      equipment: populatedEquipment,
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get All Equipment
exports.getAllEquipment = async (req, res) => {
  try {
    const { category, rentalType } = req.query;
    const query = {};

    if (category) {
      query.category = category;
    }

    if (rentalType) {
      query.rentalType = rentalType;
    }

    const equipment = await Equipment.find(query)
      .populate('owner', 'name role email')
      .sort({ createdAt: -1 });

    return res.json({ equipment });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get Current User Equipment
exports.getMyEquipment = async (req, res) => {
  try {
    const equipment = await Equipment.find({ owner: req.userId })
      .populate('owner', 'name role email')
      .sort({ createdAt: -1 });

    return res.json({ equipment });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get Equipment by ID
exports.getEquipmentById = async (req, res) => {
  try {
    const equipment = await Equipment.findById(req.params.id)
      .populate('owner', 'name role email');

    if (!equipment) {
      return res.status(404).json({ message: 'Equipment not found' });
    }

    return res.json({ equipment });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Update Equipment
exports.updateEquipment = async (req, res) => {
  try {
    const equipment = await Equipment.findOne({
      _id: req.params.id,
      owner: req.userId,
    });

    if (!equipment) {
      return res.status(404).json({ message: 'Equipment not found' });
    }

    const allowedFields = [
      'name',
      'category',
      'description',
      'condition',
      'availability',
      'rentalType',
      'pricePerDay',
      'location',
    ];

    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        equipment[field] = field === 'pricePerDay'
          ? Number(req.body[field]) || 0
          : req.body[field];
      }
    });

    await equipment.save();

    const populatedEquipment = await Equipment.findById(equipment._id)
      .populate('owner', 'name role email');

    return res.json({
      message: 'Equipment updated successfully',
      equipment: populatedEquipment,
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Delete Equipment
exports.deleteEquipment = async (req, res) => {
  try {
    const equipment = await Equipment.findOneAndDelete({
      _id: req.params.id,
      owner: req.userId,
    });

    if (!equipment) {
      return res.status(404).json({ message: 'Equipment not found' });
    }

    return res.json({ message: 'Equipment deleted successfully' });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};
