const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const {
  listEquipment,
  getAllEquipment,
  getMyEquipment,
  getEquipmentById,
  updateEquipment,
  deleteEquipment,
} = require('../controllers/equipment.controller');

router.post('/', auth, listEquipment);
router.get('/', getAllEquipment);
router.get('/my', auth, getMyEquipment);
router.get('/:id', getEquipmentById);
router.put('/:id', auth, updateEquipment);
router.delete('/:id', auth, deleteEquipment);

module.exports = router;
