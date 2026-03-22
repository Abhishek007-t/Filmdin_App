const Equipment = require('../models/equipment.model');

// Add new equipment listing
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
      images,
    } = req.body;

    if (!name || !category) {
      return res.status(400).json({ message: 'Name and category are required' });
    }

    const shouldBeFree = rentalType === 'Lend';

    const equipment = await Equipment.create({
      owner: req.userId,
      name,
      category,
      description,
      condition,
      availability,
      rentalType,
      pricePerDay: shouldBeFree ? 0 : Number(pricePerDay || 0),
      location,
      images: Array.isArray(images) ? images : [],
    });

    const populatedEquipment = await Equipment.findById(equipment._id)
      .populate('owner', 'name role profilePhoto location');

    res.status(201).json({
      message: 'Equipment listed successfully',
      equipment: populatedEquipment,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get all available equipment with optional filters
exports.getAllEquipment = async (req, res) => {
  try {
    const { category, location, rentalType } = req.query;

    const filter = { availability: 'Available' };

    if (category) {
      filter.category = category;
    }

    if (rentalType) {
      filter.rentalType = rentalType;
    }

    if (location) {
      filter.location = { $regex: location, $options: 'i' };
    }

    const equipment = await Equipment.find(filter)
      .populate('owner', 'name role profilePhoto location')
      .sort({ createdAt: -1 });

    res.json({ equipment });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get equipment listed by current user
exports.getMyEquipment = async (req, res) => {
  try {
    const equipment = await Equipment.find({ owner: req.userId })
      .populate('owner', 'name role profilePhoto location')
      .sort({ createdAt: -1 });

    res.json({ equipment });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get equipment details
exports.getEquipmentById = async (req, res) => {
  try {
    const equipment = await Equipment.findById(req.params.id)
      .populate('owner', 'name role profilePhoto location')
      .populate('requests.requester', 'name role profilePhoto');

    if (!equipment) {
      return res.status(404).json({ message: 'Equipment not found' });
    }

    res.json({ equipment });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Update equipment (owner only)
exports.updateEquipment = async (req, res) => {
  try {
    const equipment = await Equipment.findOne({
      _id: req.params.id,
      owner: req.userId,
    });

    if (!equipment) {
      return res.status(404).json({ message: 'Equipment not found or not authorized' });
    }

    const allowedUpdates = [
      'name',
      'category',
      'description',
      'condition',
      'availability',
      'rentalType',
      'pricePerDay',
      'location',
      'images',
    ];

    allowedUpdates.forEach((field) => {
      if (Object.prototype.hasOwnProperty.call(req.body, field)) {
        equipment[field] = req.body[field];
      }
    });

    if (equipment.rentalType === 'Lend') {
      equipment.pricePerDay = 0;
    } else if (req.body.pricePerDay !== undefined) {
      equipment.pricePerDay = Number(req.body.pricePerDay || 0);
    }

    await equipment.save();

    const populatedEquipment = await Equipment.findById(equipment._id)
      .populate('owner', 'name role profilePhoto location');

    res.json({
      message: 'Equipment updated successfully',
      equipment: populatedEquipment,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Delete equipment (owner only)
exports.deleteEquipment = async (req, res) => {
  try {
    const equipment = await Equipment.findOneAndDelete({
      _id: req.params.id,
      owner: req.userId,
    });

    if (!equipment) {
      return res.status(404).json({ message: 'Equipment not found or not authorized' });
    }

    res.json({ message: 'Equipment deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Request rental/lending from owner
exports.requestEquipment = async (req, res) => {
  try {
    const { message } = req.body;

    const equipment = await Equipment.findById(req.params.id);

    if (!equipment) {
      return res.status(404).json({ message: 'Equipment not found' });
    }

    if (equipment.owner.toString() === req.userId) {
      return res.status(400).json({ message: 'You cannot request your own equipment' });
    }

    if (equipment.availability !== 'Available') {
      return res.status(400).json({ message: 'Equipment is not currently available' });
    }

    const existingPendingRequest = equipment.requests.find(
      (request) => request.requester.toString() === req.userId && request.status === 'Pending'
    );

    if (existingPendingRequest) {
      return res.status(400).json({ message: 'You already have a pending request for this equipment' });
    }

    equipment.requests.push({
      requester: req.userId,
      message: message || '',
    });

    await equipment.save();

    res.status(201).json({ message: 'Equipment request sent successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};
