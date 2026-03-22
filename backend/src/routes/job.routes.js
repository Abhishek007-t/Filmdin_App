const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const {
  createJob,
  getAllJobs,
  getMyJobs,
  getJobById,
  applyToJob,
  deleteJob,
  closeJob,
} = require('../controllers/job.controller');

router.post('/', auth, createJob);
router.get('/', getAllJobs);
router.get('/my', auth, getMyJobs);
router.get('/:id', getJobById);
router.post('/:id/apply', auth, applyToJob);
router.delete('/:id', auth, deleteJob);
router.put('/:id/close', auth, closeJob);

module.exports = router;