const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const {
  searchUsers,
  getUserProfile,
  updateProfile,
  getAllUsers,
  followUser,
  unfollowUser,
  getFollowersList,
  getFollowingList,
  getMyStats,
} = require('../controllers/user.controller');

router.get('/search', auth, searchUsers);
router.get('/all', auth, getAllUsers);
router.put('/profile', auth, updateProfile);
router.put('/follow/:id', auth, followUser);
router.put('/unfollow/:id', auth, unfollowUser);
router.get('/followers/:id', auth, getFollowersList);
router.get('/following/:id', auth, getFollowingList);
router.get('/stats/me', auth, getMyStats);
router.get('/:id', auth, getUserProfile);

module.exports = router;