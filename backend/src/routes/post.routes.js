const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const {
  createPost,
  getFeedPosts,
  likePost,
  deletePost,
} = require('../controllers/post.controller');

router.post('/', auth, createPost);
router.get('/feed', getFeedPosts);
router.put('/like/:id', auth, likePost);
router.delete('/:id', auth, deletePost);

module.exports = router;