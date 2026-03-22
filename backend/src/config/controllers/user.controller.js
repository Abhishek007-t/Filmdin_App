const User = require('../models/user.model');
const Credit = require('../models/credit.model');

const sanitizeUser = '-password';

// Search Users
exports.searchUsers = async (req, res) => {
  try {
    const { q, role } = req.query;

    let query = {};

    if (q) {
      query.$or = [
        { name: { $regex: q, $options: 'i' } },
        { bio: { $regex: q, $options: 'i' } },
      ];
    }

    if (role) {
      query.role = role;
    }

    const users = await User.find(query).select(sanitizeUser).limit(20);

    res.json({ users });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get All Users
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find({ _id: { $ne: req.userId } })
      .select(sanitizeUser)
      .limit(20);

    res.json({ users });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get User Profile
exports.getUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select(sanitizeUser);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const credits = await Credit.find({ user: req.params.id })
      .sort({ year: -1 });

    res.json({ user, credits });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Follow User
exports.followUser = async (req, res) => {
  try {
    const currentUserId = req.userId;
    const targetUserId = req.params.id;

    if (currentUserId === targetUserId) {
      return res.status(400).json({ message: 'You cannot follow yourself' });
    }

    const [currentUser, targetUser] = await Promise.all([
      User.findById(currentUserId),
      User.findById(targetUserId),
    ]);

    if (!currentUser || !targetUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    const alreadyFollowing = currentUser.following.some(
      (id) => id.toString() === targetUserId,
    );

    if (alreadyFollowing) {
      return res.status(400).json({ message: 'Already following this user' });
    }

    await Promise.all([
      User.findByIdAndUpdate(currentUserId, {
        $addToSet: { following: targetUserId },
      }),
      User.findByIdAndUpdate(targetUserId, {
        $addToSet: { followers: currentUserId },
      }),
    ]);

    const updatedTargetUser = await User.findById(targetUserId).select(sanitizeUser);

    return res.json({
      message: 'Followed successfully',
      user: updatedTargetUser,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Unfollow User
exports.unfollowUser = async (req, res) => {
  try {
    const currentUserId = req.userId;
    const targetUserId = req.params.id;

    if (currentUserId === targetUserId) {
      return res.status(400).json({ message: 'You cannot unfollow yourself' });
    }

    const [currentUser, targetUser] = await Promise.all([
      User.findById(currentUserId),
      User.findById(targetUserId),
    ]);

    if (!currentUser || !targetUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    const isFollowing = currentUser.following.some(
      (id) => id.toString() === targetUserId,
    );

    if (!isFollowing) {
      return res.status(400).json({ message: 'You are not following this user' });
    }

    await Promise.all([
      User.findByIdAndUpdate(currentUserId, {
        $pull: { following: targetUserId },
      }),
      User.findByIdAndUpdate(targetUserId, {
        $pull: { followers: currentUserId },
      }),
    ]);

    const updatedTargetUser = await User.findById(targetUserId).select(sanitizeUser);

    return res.json({
      message: 'Unfollowed successfully',
      user: updatedTargetUser,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get Followers List
exports.getFollowersList = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .select('followers')
      .populate('followers', sanitizeUser);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      count: user.followers.length,
      followers: user.followers,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get Following List
exports.getFollowingList = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .select('following')
      .populate('following', sanitizeUser);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      count: user.following.length,
      following: user.following,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};