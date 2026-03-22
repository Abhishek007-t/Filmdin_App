const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const { searchUsers, getAllUsers, getUserProfile, followUser, unfollowUser, getFollowersList, getFollowingList, updateProfile, getMyStats } = require('../controllers/user.controller');
const {
  searchUsers,
  getUserProfile,
  updateProfile,
  getAllUsers,
  followUser,
  unfollowUser,
  getFollowersList,
  getFollowingList,
} = require('../controllers/user.controller');

router.get('/search', auth, searchUsers);
router.get('/all', auth, getAllUsers);
router.put('/profile', auth, updateProfile);
router.put('/follow/:id', auth, followUser);
router.put('/unfollow/:id', auth, unfollowUser);
router.get('/followers/:id', auth, getFollowersList);
router.get('/following/:id', auth, getFollowingList);
router.get('/:id', auth, getUserProfile);
router.get('/stats/me', auth, getMyStats);

module.exports = router;