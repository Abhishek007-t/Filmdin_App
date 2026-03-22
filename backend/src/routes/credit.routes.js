const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const {
  addCredit,
  getMyCredits,
  getUserCredits,
  deleteCredit,
} = require('../controllers/credit.controller');

router.post('/', auth, addCredit);
router.get('/my', auth, getMyCredits);
router.get('/user/:userId', getUserCredits);
router.delete('/:id', auth, deleteCredit);

module.exports = router;