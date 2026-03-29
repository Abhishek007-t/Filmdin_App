import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../services/api_service.dart';
import '../widgets/loading_skeleton.dart';
import 'login_screen.dart';
import 'add_credit_screen.dart';
import 'user_profile_screen.dart';
import 'equipment_screen.dart';
import 'jobs_screen.dart';
import 'edit_profile_screen.dart';

bool isOwner(dynamic ownerId, String? currentUserId) {
  if (currentUserId == null) return false;
  if (ownerId == null) return false;
  if (ownerId is Map) {
    return (ownerId['_id'] ?? ownerId['id'])?.toString() == currentUserId;
  }
  return ownerId.toString() == currentUserId;
}

ImageProvider<Object>? profileImageProvider(dynamic profilePhoto) {
  if (profilePhoto == null) return null;

  final String value = profilePhoto.toString().trim();
  if (value.isEmpty) return null;

  if (value.startsWith('data:image')) {
    final commaIndex = value.indexOf(',');
    if (commaIndex == -1) return null;
    final raw = value.substring(commaIndex + 1);
    return MemoryImage(base64Decode(raw));
  }

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return NetworkImage(value);
  }

  return null;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FeedTab(),
    const SearchTab(),
    const EquipmentScreen(),
    const JobsScreen(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.darkGrey, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppTheme.black,
          selectedItemColor: AppTheme.gold,
          unselectedItemColor: AppTheme.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'Equipment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FEED TAB ───────────────────────────────────────────
class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      postProvider.fetchPosts(token: authProvider.token ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final composerAvatar = profileImageProvider(authProvider.user?['profilePhoto']);

    return SafeArea(
      child: Column(
        children: [
          // Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FILMDIN',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.white,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Create Post Box
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    borderRadius: BorderRadius.circular(20),
                    image: composerAvatar != null
                        ? DecorationImage(image: composerAvatar, fit: BoxFit.cover)
                        : null,
                  ),
                  child: composerAvatar == null
                      ? Center(
                          child: Text(
                            (authProvider.user?['name'] ?? 'F')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showCreatePostDialog(
                      context,
                      authProvider,
                      postProvider,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.black,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Share something with filmmakers...',
                        style: TextStyle(
                          color: AppTheme.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Posts List
          Expanded(
            child: postProvider.isLoading
                ? const SkeletonList(
                    itemCount: 5,
                    itemHeight: 130,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  )
                : postProvider.posts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.movie_creation_outlined,
                              color: AppTheme.grey,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No posts yet',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Be the first to share something!',
                              style: TextStyle(color: AppTheme.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.gold,
                        onRefresh: () => postProvider.fetchPosts(
                          token: authProvider.token ?? '',
                        ),
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: postProvider.posts.length,
                          itemBuilder: (context, index) {
                            final post = postProvider.posts[index];
                            final canDelete = isOwner(
                              post['user'],
                              authProvider.user?['id']?.toString(),
                            );

                            return _RealPostCard(
                              post: post,
                              canDelete: canDelete,
                              onLike: () => postProvider.likePost(
                                token: authProvider.token ?? '',
                                postId: post['_id'],
                              ),
                              onComment: (text) => postProvider.addComment(
                                token: authProvider.token ?? '',
                                postId: post['_id'].toString(),
                                text: text,
                              ),
                              onDelete: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    backgroundColor: AppTheme.darkGrey,
                                    title: const Text(
                                      'Confirm Delete',
                                      style: TextStyle(color: AppTheme.white),
                                    ),
                                    content: const Text(
                                      'Delete this post?',
                                      style: TextStyle(color: AppTheme.grey),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext, false),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(color: AppTheme.grey),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldDelete != true) {
                                  return;
                                }

                                final result = await ApiService.deletePost(
                                  token: authProvider.token ?? '',
                                  postId: post['_id'].toString(),
                                );

                                if (!context.mounted) {
                                  return;
                                }

                                if (result['success'] == true) {
                                  postProvider.removePost(post['_id'].toString());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Post deleted successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        (result['message'] ?? 'Failed to delete post').toString(),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog(
    BuildContext context,
    AuthProvider authProvider,
    PostProvider postProvider,
  ) {
    String? selectedMediaPath;
    bool selectedIsVideo = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkGrey,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Post',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _postController,
                maxLines: 4,
                autofocus: true,
                style: const TextStyle(color: AppTheme.white),
                decoration: InputDecoration(
                  hintText: 'What is on your mind?',
                  hintStyle: const TextStyle(color: AppTheme.grey),
                  filled: true,
                  fillColor: AppTheme.black,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await _picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setSheetState(() {
                          selectedMediaPath = picked.path;
                          selectedIsVideo = false;
                        });
                      }
                    },
                    icon: const Icon(Icons.image_outlined, color: AppTheme.gold),
                    label: const Text('Image', style: TextStyle(color: AppTheme.gold)),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await _picker.pickVideo(source: ImageSource.gallery);
                      if (picked != null) {
                        setSheetState(() {
                          selectedMediaPath = picked.path;
                          selectedIsVideo = true;
                        });
                      }
                    },
                    icon: const Icon(Icons.videocam_outlined, color: AppTheme.gold),
                    label: const Text('Video', style: TextStyle(color: AppTheme.gold)),
                  ),
                  if (selectedMediaPath != null)
                    IconButton(
                      onPressed: () {
                        setSheetState(() {
                          selectedMediaPath = null;
                          selectedIsVideo = false;
                        });
                      },
                      icon: const Icon(Icons.close, color: AppTheme.grey),
                    ),
                ],
              ),
              if (selectedMediaPath != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: selectedIsVideo
                      ? Container(
                          width: double.infinity,
                          height: 160,
                          color: AppTheme.black,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_circle_fill, color: AppTheme.gold, size: 44),
                                SizedBox(height: 8),
                                Text('Video selected', style: TextStyle(color: AppTheme.white)),
                              ],
                            ),
                          ),
                        )
                      : Image.file(
                          File(selectedMediaPath!),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final content = _postController.text.trim();
                    if (content.isEmpty && selectedMediaPath == null) {
                      return;
                    }

                    final success = await postProvider.createPost(
                      token: authProvider.token ?? '',
                      content: content,
                      mediaPath: selectedMediaPath,
                    );

                    if (success && context.mounted) {
                      _postController.clear();
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Post',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── REAL POST CARD ──────────────────────────────────────
class _RealPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLike;
  final Future<List<dynamic>?> Function(String text)? onComment;
  final bool canDelete;
  final Future<void> Function()? onDelete;

  const _RealPostCard({
    required this.post,
    required this.onLike,
    this.onComment,
    this.canDelete = false,
    this.onDelete,
  });

  String _timeAgo(String dateStr) {
    final date = DateTime.parse(dateStr);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final user = post['user'] as Map<String, dynamic>? ?? {};
    final name = user['name'] ?? 'Unknown';
    final role = user['role'] ?? 'Filmmaker';
    final avatar = profileImageProvider(user['profilePhoto']);
    final mediaUrl = (post['imageUrl'] ?? '').toString();
    final mediaType = (post['mediaType'] ?? '').toString();
    final likes = post['likes'] as List? ?? [];
    final isLiked = post['isLiked'] ?? false;
    final likesCount = post['likesCount'] ?? likes.length;
    final commentsCount = post['commentsCount'] ?? (post['comments'] as List? ?? []).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.gold,
                  borderRadius: BorderRadius.circular(22),
                  image: avatar != null
                      ? DecorationImage(image: avatar, fit: BoxFit.cover)
                      : null,
                ),
                child: avatar == null
                    ? Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'F',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$role • ${_timeAgo(post['createdAt'])}',
                      style: const TextStyle(
                        color: AppTheme.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (canDelete)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppTheme.grey),
                  color: AppTheme.darkGrey,
                  onSelected: (value) async {
                    if (value == 'delete' && onDelete != null) {
                      await onDelete!();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post['content'] ?? '',
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (mediaUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: mediaType == 'video'
                  ? FeedVideoPlayer(mediaUrl: mediaUrl)
                  : (mediaUrl.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(mediaUrl.split(',').last),
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          mediaUrl,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        )),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : AppTheme.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$likesCount',
                      style: TextStyle(
                        color: isLiked ? Colors.red : AppTheme.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => _openComments(context),
                child: Row(
                  children: [
                    const Icon(
                      Icons.comment_outlined,
                      color: AppTheme.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$commentsCount',
                      style: const TextStyle(
                        color: AppTheme.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () {
                  final text = (post['content'] ?? '').toString();
                  SharePlus.instance.share(
                    ShareParams(
                      text: text.isNotEmpty ? text : 'Check this post on Filmdin',
                    ),
                  );
                },
                child: const Icon(
                  Icons.share_outlined,
                  color: AppTheme.grey,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openComments(BuildContext context) {
    final controller = TextEditingController();
    List<dynamic> comments = List<dynamic>.from(post['comments'] as List? ?? []);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkGrey,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Comments',
                style: TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: comments.isEmpty
                    ? const Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(color: AppTheme.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index] as Map<String, dynamic>;
                          final commentUser = comment['user'] as Map<String, dynamic>? ?? {};
                          final commentName = (commentUser['name'] ?? 'User').toString();
                          final commentText = (comment['text'] ?? '').toString();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.gold,
                                  child: Text(
                                    commentName.isNotEmpty ? commentName[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.black,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          commentName,
                                          style: const TextStyle(
                                            color: AppTheme.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          commentText,
                                          style: const TextStyle(color: AppTheme.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: AppTheme.white),
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: const TextStyle(color: AppTheme.grey),
                        filled: true,
                        fillColor: AppTheme.black,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty || onComment == null) return;

                      final updatedComments = await onComment!(text);
                      if (updatedComments != null) {
                        setSheetState(() {
                          comments = updatedComments;
                        });
                        controller.clear();
                      } else {
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to add comment. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.send, color: AppTheme.gold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedVideoPlayer extends StatefulWidget {
  final String mediaUrl;

  const FeedVideoPlayer({
    super.key,
    required this.mediaUrl,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;
  String? _tempPath;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final source = widget.mediaUrl.trim();
      if (source.isEmpty) {
        throw Exception('Empty video source');
      }

      if (source.startsWith('data:video')) {
        final commaIndex = source.indexOf(',');
        if (commaIndex < 0) {
          throw Exception('Invalid video data URL');
        }

        final rawBase64 = source.substring(commaIndex + 1);
        final Uint8List bytes = base64Decode(rawBase64);
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/filmdin_post_${DateTime.now().microsecondsSinceEpoch}.mp4');
        await file.writeAsBytes(bytes, flush: true);
        _tempPath = file.path;
        _controller = VideoPlayerController.file(file);
      } else {
        _controller = VideoPlayerController.networkUrl(Uri.parse(source));
      }

      await _controller!.initialize();
      _controller!.setLooping(true);

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to play this video';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    if (_tempPath != null) {
      File(_tempPath!).delete().catchError((_) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: double.infinity,
        height: 220,
        color: AppTheme.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.gold),
        ),
      );
    }

    if (_error != null || _controller == null || !_controller!.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: 220,
        color: AppTheme.black,
        child: Center(
          child: Text(
            _error ?? 'Unable to play this video',
            style: const TextStyle(color: AppTheme.grey),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          Container(
            color: Colors.black26,
          ),
          GestureDetector(
            onTap: () {
              if (_controller!.value.isPlaying) {
                _controller!.pause();
              } else {
                _controller!.play();
              }
              if (mounted) {
                setState(() {});
              }
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.black54,
              child: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppTheme.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SEARCH TAB ─────────────────────────────────────────
class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _users = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _selectedRole = '';

  final List<String> roles = [
    'All',
    'Director',
    'Actor',
    'Cinematographer',
    'Producer',
    'Editor',
    'Sound Designer',
    'Screenwriter',
  ];

  Future<void> _search(String token) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final result = await ApiService.searchUsers(
      query: _searchController.text.trim(),
      token: token,
      role: _selectedRole == 'All' ? null : _selectedRole,
    );

    if (result['success']) {
      setState(() {
        _users = result['data']['users'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAll(String token) async {
    setState(() => _isLoading = true);

    final result = await ApiService.getAllUsers(token: token);

    if (result['success']) {
      setState(() {
        _users = result['data']['users'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      _loadAll(authProvider.token ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discover',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: AppTheme.white),
                          decoration: const InputDecoration(
                            hintText: 'Search filmmakers...',
                            hintStyle: TextStyle(color: AppTheme.grey),
                            border: InputBorder.none,
                            icon: Icon(Icons.search, color: AppTheme.grey),
                          ),
                          onSubmitted: (_) =>
                              _search(authProvider.token ?? ''),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _search(authProvider.token ?? ''),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Role Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: roles.length,
                    itemBuilder: (context, index) {
                      final role = roles[index];
                      final isSelected = _selectedRole == role ||
                          (_selectedRole.isEmpty && role == 'All');
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRole = role == 'All' ? '' : role;
                          });
                          _search(authProvider.token ?? '');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.gold
                                : AppTheme.darkGrey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : AppTheme.white,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const SkeletonList(itemCount: 6, itemHeight: 82)
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              color: AppTheme.grey,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _hasSearched
                                  ? 'No users found'
                                  : 'No users yet',
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return _UserCard(user: user);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? 'Unknown';
    final role = user['role'] ?? 'Filmmaker';
    final bio = user['bio'] ?? '';
    final followers = (user['followers'] as List? ?? []).length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(
              userId: user['_id'],
              userName: name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.gold,
                borderRadius: BorderRadius.circular(27),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'F',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 13,
                    ),
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      bio,
                      style: const TextStyle(
                        color: AppTheme.grey,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '$followers followers',
                    style: const TextStyle(
                      color: AppTheme.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROFILE TAB ────────────────────────────────────────
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int _refreshCounter = 0;

  ImageProvider<Object>? _avatarImageProvider(dynamic profilePhoto) {
    final photo = (profilePhoto ?? '').toString().trim();
    if (photo.isEmpty) return null;

    if (photo.startsWith('data:image')) {
      final parts = photo.split(',');
      if (parts.length == 2) {
        try {
          return MemoryImage(base64Decode(parts[1]));
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return NetworkImage(photo);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?['name'] ?? 'Your Name';
    final userRole = authProvider.user?['role'] ?? 'Filmmaker';
    final userLocation = authProvider.user?['location'] ?? '';
    final avatarImage = _avatarImageProvider(authProvider.user?['profilePhoto']);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _refreshCounter++;
          });
        },
        child: SingleChildScrollView(
          child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppTheme.darkGrey,
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      borderRadius: BorderRadius.circular(45),
                      image: avatarImage != null
                          ? DecorationImage(image: avatarImage, fit: BoxFit.cover)
                          : null,
                    ),
                    child: avatarImage == null
                        ? Center(
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'F',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userLocation.isNotEmpty ? '$userRole • $userLocation' : userRole,
                    style: const TextStyle(
                      color: AppTheme.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>>(
                    key: ValueKey('stats_$_refreshCounter'),
                    future: ApiService.getMyStats(token: authProvider.token ?? ''),
                    builder: (context, snapshot) {
                      int projects = 0;
                      int followers = 0;
                      int following = 0;

                      if (snapshot.hasData && snapshot.data!['success'] == true) {
                        final data = snapshot.data!['data'] as Map<String, dynamic>;
                        projects = data['projectsCount'] ?? 0;
                        followers = data['followersCount'] ?? 0;
                        following = data['followingCount'] ?? 0;
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(label: 'Projects', value: '$projects'),
                          _StatItem(label: 'Followers', value: '$followers'),
                          _StatItem(label: 'Following', value: '$following'),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.gold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(color: AppTheme.gold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await authProvider.logout();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Credits',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddCreditScreen(),
                            ),
                          );
                          if (result == true && mounted) {
                            setState(() {
                              _refreshCounter++;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.gold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '+ Add',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>>(
                    key: ValueKey('credits_$_refreshCounter'),
                    future: ApiService.getMyCredits(token: authProvider.token ?? ''),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SkeletonList(
                            itemCount: 3,
                            itemHeight: 78,
                            padding: EdgeInsets.zero,
                          ),
                        );
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!['data'] == null ||
                          (snapshot.data!['data']['credits'] as List).isEmpty) {
                        return const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.movie_creation_outlined,
                                color: AppTheme.grey,
                                size: 48,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No credits yet',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add your film projects and credits',
                                style: TextStyle(color: AppTheme.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      final credits = snapshot.data!['data']['credits'] as List;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: credits.length,
                        itemBuilder: (context, index) {
                          final credit = credits[index];
                          final canDeleteCredit = isOwner(
                            credit['user'],
                            authProvider.user?['id']?.toString(),
                          );
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.darkGrey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.gold.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.movie_outlined,
                                    color: AppTheme.gold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        credit['projectName'],
                                        style: const TextStyle(
                                          color: AppTheme.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${credit['role']} • ${credit['projectType']}',
                                        style: const TextStyle(
                                          color: AppTheme.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '${credit['year']}',
                                        style: const TextStyle(
                                          color: AppTheme.gold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                        if (canDeleteCredit)
                                          IconButton(
                                          onPressed: () async {
                                            final shouldDelete = await showDialog<bool>(
                                              context: context,
                                              builder: (dialogContext) => AlertDialog(
                                                backgroundColor: AppTheme.darkGrey,
                                                title: const Text(
                                                  'Confirm Delete',
                                                  style: TextStyle(color: AppTheme.white),
                                                ),
                                                content: const Text(
                                                  'Delete this credit?',
                                                  style: TextStyle(color: AppTheme.grey),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(dialogContext, false),
                                                    child: const Text(
                                                      'Cancel',
                                                      style: TextStyle(color: AppTheme.grey),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(dialogContext, true),
                                                    child: const Text(
                                                      'Delete',
                                                      style: TextStyle(color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (shouldDelete != true) {
                                              return;
                                            }

                                            final result = await ApiService.deleteCredit(
                                              token: authProvider.token ?? '',
                                              creditId: credit['_id'].toString(),
                                            );

                                            if (!context.mounted) {
                                              return;
                                            }

                                            if (result['success'] == true) {
                                              setState(() {
                                                _refreshCounter++;
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Credit deleted successfully'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    (result['message'] ?? 'Failed to delete credit')
                                                        .toString(),
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                        ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.grey, fontSize: 12),
        ),
      ],
    );
  }
}
