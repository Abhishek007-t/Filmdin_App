const User = require('../models/user.model');
const Credit = require('../models/credit.model');

// Search Users
exports.searchUsers = async (req, res) => {
  try {
    const { q, role } = req.query;
    const query = {};

    if (q) {
      query.$or = [
        { name: { $regex: q, $options: 'i' } },
        { bio: { $regex: q, $options: 'i' } },
      ];
    }

    if (role) {
      query.role = role;
    }

    const users = await User.find(query)
      .select('-password')
      .limit(20);

    return res.json({ users });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get All Users
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find({ _id: { $ne: req.userId } })
      .select('-password')
      .limit(20);

    return res.json({ users });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get User Profile
exports.getUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const credits = await Credit.find({ user: req.params.id })
      .sort({ year: -1 });

    return res.json({ user, credits });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Update My Profile
exports.updateProfile = async (req, res) => {
  try {
    const { name, bio, location, role } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ message: 'Name is required' });
    }

    let profilePhoto;
    if (req.file) {
      if (!req.file.mimetype || !req.file.mimetype.startsWith('image/')) {
        return res.status(400).json({ message: 'Only image files are allowed' });
      }
      profilePhoto = `data:${req.file.mimetype};base64,${req.file.buffer.toString('base64')}`;
    }

    const updateData = {
      name: name.trim(),
      bio: bio ?? '',
      location: location ?? '',
      role,
    };

    if (profilePhoto) {
      updateData.profilePhoto = profilePhoto;
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.userId,
      updateData,
      { new: true, runValidators: true },
    ).select('-password');

    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    return res.json({
      message: 'Profile updated successfully',
      user: updatedUser,
    });
  } catch (error) {
    return res.status(500).json({
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

    return res.json({ message: 'Followed successfully' });
  } catch (error) {
    return res.status(500).json({
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

    await Promise.all([
      User.findByIdAndUpdate(currentUserId, {
        $pull: { following: targetUserId },
      }),
      User.findByIdAndUpdate(targetUserId, {
        $pull: { followers: currentUserId },
      }),
    ]);

    return res.json({ message: 'Unfollowed successfully' });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get Followers List
exports.getFollowersList = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .populate('followers', 'name role profilePhoto');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    return res.json({ followers: user.followers });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

// Get Following List
exports.getFollowingList = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .populate('following', 'name role profilePhoto');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    return res.json({ following: user.following });
  } catch (error) {
    return res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};
// Get My Profile Stats
exports.getMyStats = async (req, res) => {
  try {
    const user = await User.findById(req.userId)
      .select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const creditsCount = await Credit.countDocuments({ user: req.userId });

    res.json({
      followersCount: user.followers.length,
      followingCount: user.following.length,
      projectsCount: creditsCount,
      user,
    });
  } catch (error) {
    res.status(500).json({
      message: 'Server error',
      error: error.message,
    });
  }
};

