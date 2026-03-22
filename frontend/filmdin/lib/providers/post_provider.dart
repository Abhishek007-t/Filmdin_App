import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PostProvider extends ChangeNotifier {
  List<dynamic> _posts = [];
  bool _isLoading = false;

  List<dynamic> get posts => _posts;
  bool get isLoading => _isLoading;

  // Fetch Feed Posts
  Future<void> fetchPosts({required String token}) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.getFeedPosts(token: token);

    if (result['success']) {
      _posts = result['data']['posts'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create Post
  Future<bool> createPost({
    required String token,
    required String content,
  }) async {
    final result = await ApiService.createPost(
      token: token,
      content: content,
    );

    if (result['success']) {
      _posts.insert(0, result['data']['post']);
      notifyListeners();
      return true;
    }
    return false;
  }

  // Like Post
  Future<void> likePost({
    required String token,
    required String postId,
  }) async {
    final result = await ApiService.likePost(
      token: token,
      postId: postId,
    );

    if (result['success']) {
      final index = _posts.indexWhere((p) => p['_id'] == postId);
      if (index != -1) {
        _posts[index]['isLiked'] = result['data']['isLiked'];
        _posts[index]['likesCount'] = result['data']['likesCount'];
        notifyListeners();
      }
    }
  }
}