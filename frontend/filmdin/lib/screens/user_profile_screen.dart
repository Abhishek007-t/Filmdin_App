import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? userData;
  List<dynamic> credits = [];
  bool isLoading = true;
  bool isFollowLoading = false;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?['_id'];
    final result = await ApiService.getUserProfile(
      userId: widget.userId,
      token: authProvider.token ?? '',
    );

    if (result['success']) {
      final user = result['data']['user'] as Map<String, dynamic>;
      final followers = user['followers'] as List? ?? [];
      setState(() {
        userData = user;
        credits = result['data']['credits'];
        isFollowing =
            currentUserId != null && followers.contains(currentUserId);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token ?? '';
    if (token.isEmpty || userData == null || isFollowLoading) {
      return;
    }

    setState(() => isFollowLoading = true);

    final result = isFollowing
        ? await ApiService.unfollowUser(token: token, userId: widget.userId)
        : await ApiService.followUser(token: token, userId: widget.userId);

    if (!mounted) return;

    if (result['success']) {
      final followers = List<dynamic>.from(
        userData!['followers'] as List? ?? [],
      );
      final currentUserId = authProvider.user?['_id'];

      if (currentUserId != null) {
        if (isFollowing) {
          followers.remove(currentUserId);
        } else {
          followers.add(currentUserId);
        }
      }

      setState(() {
        isFollowing = !isFollowing;
        userData = {...userData!, 'followers': followers};
        isFollowLoading = false;
      });
    } else {
      setState(() => isFollowLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to update follow status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwnProfile = widget.userId == authProvider.user?['_id'];

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.userName,
          style: const TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : userData == null
          ? const Center(
              child: Text(
                'User not found',
                style: TextStyle(color: AppTheme.white),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: AppTheme.darkGrey,
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppTheme.gold,
                            borderRadius: BorderRadius.circular(45),
                          ),
                          child: Center(
                            child: Text(
                              (userData!['name'] ?? 'F')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData!['name'] ?? '',
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userData!['role'] ?? 'Filmmaker',
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (userData!['bio'] != null &&
                            userData!['bio'].isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            userData!['bio'],
                            style: const TextStyle(
                              color: AppTheme.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(
                              label: 'Projects',
                              value: '${credits.length}',
                            ),
                            _StatItem(
                              label: 'Followers',
                              value:
                                  '${(userData!['followers'] as List? ?? []).length}',
                            ),
                            _StatItem(
                              label: 'Following',
                              value:
                                  '${(userData!['following'] as List? ?? []).length}',
                            ),
                          ],
                        ),
                        if (!isOwnProfile) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isFollowLoading ? null : _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? AppTheme.darkGrey
                                    : AppTheme.gold,
                                foregroundColor: isFollowing
                                    ? AppTheme.white
                                    : Colors.black,
                                disabledBackgroundColor: AppTheme.darkGrey,
                                disabledForegroundColor: AppTheme.grey,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: isFollowing
                                        ? AppTheme.gold
                                        : AppTheme.gold,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isFollowLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.gold,
                                      ),
                                    )
                                  : Text(
                                      isFollowing ? 'Following' : 'Follow',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Credits Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${userData!['name']}\'s Credits',
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        credits.isEmpty
                            ? const Center(
                                child: Text(
                                  'No credits yet',
                                  style: TextStyle(color: AppTheme.grey),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: credits.length,
                                itemBuilder: (context, index) {
                                  final credit = credits[index];
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
                                            color: AppTheme.gold.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.movie_outlined,
                                            color: AppTheme.gold,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
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
        Text(label, style: const TextStyle(color: AppTheme.grey, fontSize: 12)),
      ],
    );
  }
}
