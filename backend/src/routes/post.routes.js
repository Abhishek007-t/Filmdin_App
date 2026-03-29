const express = require('express');
const router = express.Router();
const multer = require('multer');
const auth = require('../middleware/auth.middleware');
const {
  createPost,
  getFeedPosts,
  likePost,
  addComment,
  deletePost,
} = require('../controllers/post.controller');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 20 * 1024 * 1024 },
});

router.post('/', auth, upload.single('media'), createPost);
router.get('/feed', auth, getFeedPosts);
router.put('/like/:id', auth, likePost);
router.post('/comment/:id', auth, addComment);
router.delete('/:id', auth, deletePost);

module.exports = router;