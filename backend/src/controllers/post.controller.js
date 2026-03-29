const Post = require('../models/post.model');

const populatePost = (query) => query
  .populate('user', 'name role profilePhoto')
  .populate('comments.user', 'name role profilePhoto');

const toFeedPost = (postDoc, currentUserId) => {
  const post = postDoc.toObject();
  const likes = Array.isArray(post.likes) ? post.likes : [];
  const comments = Array.isArray(post.comments) ? post.comments : [];

  return {
    ...post,
    likesCount: likes.length,
    commentsCount: comments.length,
    isLiked: likes.some((id) => id.toString() === currentUserId),
  };
};

// Create Post
exports.createPost = async (req, res) => {
  try {
    const content = (req.body.content || '').toString().trim();
    const hasMedia = !!req.file;

    if (!content && !hasMedia) {
      return res.status(400).json({
        message: 'Post content or media is required',
      });
    }

    let mediaUrl = '';
    let mediaType = '';

    if (hasMedia) {
      if (!req.file.mimetype ||
          (!req.file.mimetype.startsWith('image/') && !req.file.mimetype.startsWith('video/'))) {
        return res.status(400).json({ message: 'Only image or video files are allowed' });
      }

      mediaType = req.file.mimetype.startsWith('video/') ? 'video' : 'image';
      mediaUrl = `data:${req.file.mimetype};base64,${req.file.buffer.toString('base64')}`;
    }

    const post = await Post.create({
      user: req.userId,
      content: content || 'Shared a post',
      imageUrl: mediaUrl,
      mediaType,
    });

    const populatedPost = await populatePost(Post.findById(post._id));

    return res.status(201).json({ post: toFeedPost(populatedPost, req.userId) });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get Feed Posts
exports.getFeedPosts = async (req, res) => {
  try {
    const posts = await populatePost(Post.find())
      .sort({ createdAt: -1 })
      .limit(20);

    return res.json({ posts: posts.map((post) => toFeedPost(post, req.userId)) });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Like Post
exports.likePost = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const isLiked = post.likes.includes(req.userId);

    if (isLiked) {
      post.likes = post.likes.filter(
        (id) => id.toString() !== req.userId,
      );
    } else {
      post.likes.push(req.userId);
    }

    await post.save();

    return res.json({
      message: isLiked ? 'Post unliked' : 'Post liked',
      likesCount: post.likes.length,
      isLiked: !isLiked,
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Add Comment
exports.addComment = async (req, res) => {
  try {
    const text = (req.body.text || '').toString().trim();

    if (!text) {
      return res.status(400).json({ message: 'Comment text is required' });
    }

    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    post.comments.push({
      user: req.userId,
      text,
    });

    await post.save();

    const updatedPost = await populatePost(Post.findById(req.params.id));

    return res.json({
      message: 'Comment added',
      comments: updatedPost.comments,
      commentsCount: updatedPost.comments.length,
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Delete Post
exports.deletePost = async (req, res) => {
  try {
    const post = await Post.findOneAndDelete({
      _id: req.params.id,
      user: req.userId,
    });

    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    return res.json({ message: 'Post deleted successfully' });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};
