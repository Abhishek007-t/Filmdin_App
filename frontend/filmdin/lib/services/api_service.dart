import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.109:5000/api';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Map<String, dynamic> _handleDioError(DioException e) {
    final dynamic responseData = e.response?.data;
    String message = 'Something went wrong';

    if (responseData is Map<String, dynamic>) {
      message = (responseData['message'] ?? 'Something went wrong').toString();
    } else if (responseData is String && responseData.trim().isNotEmpty) {
      message = responseData;
    } else if (e.message != null && e.message!.trim().isNotEmpty) {
      message = e.message!;
    }

    return {'success': false, 'message': message};
  }

  // ─── AUTH ────────────────────────────────────────────

  // Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Update Profile
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String bio,
    required String location,
    required String role,
  }) async {
    try {
      final response = await _dio.put(
        '/users/profile',
        data: {'name': name, 'bio': bio, 'location': location, 'role': role},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // ─── CREDITS ─────────────────────────────────────────

  // Add Credit
  static Future<Map<String, dynamic>> addCredit({
    required String token,
    required String projectName,
    required String projectType,
    required String role,
    required int year,
    required String description,
  }) async {
    try {
      final response = await _dio.post(
        '/credits',
        data: {
          'projectName': projectName,
          'projectType': projectType,
          'role': role,
          'year': year,
          'description': description,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get My Credits
  static Future<Map<String, dynamic>> getMyCredits({
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/credits/my',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get Credits by User ID
  static Future<Map<String, dynamic>> getUserCredits({
    required String userId,
  }) async {
    try {
      final response = await _dio.get('/credits/user/$userId');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Delete Credit
  static Future<Map<String, dynamic>> deleteCredit({
    required String token,
    required String creditId,
  }) async {
    try {
      final response = await _dio.delete(
        '/credits/$creditId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // ─── POSTS ───────────────────────────────────────────

  // Create Post
  static Future<Map<String, dynamic>> createPost({
    required String token,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        '/posts',
        data: {'content': content},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get Feed Posts
  static Future<Map<String, dynamic>> getFeedPosts({
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/posts/feed',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Like Post
  static Future<Map<String, dynamic>> likePost({
    required String token,
    required String postId,
  }) async {
    try {
      final response = await _dio.put(
        '/posts/like/$postId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // ─── EQUIPMENT ───────────────────────────────────────

  // List Equipment
  static Future<Map<String, dynamic>> listEquipment({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post(
        '/equipment',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get All Equipment
  static Future<Map<String, dynamic>> getAllEquipment({
    required String token,
    String? category,
    String? rentalType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (rentalType != null && rentalType.isNotEmpty) {
        queryParams['rentalType'] = rentalType;
      }

      final response = await _dio.get(
        '/equipment',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get My Equipment
  static Future<Map<String, dynamic>> getMyEquipment({
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/equipment/my',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get Equipment By Id
  static Future<Map<String, dynamic>> getEquipmentById({
    required String token,
    required String equipmentId,
  }) async {
    try {
      final response = await _dio.get(
        '/equipment/$equipmentId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Delete Equipment
  static Future<Map<String, dynamic>> deleteEquipment({
    required String token,
    required String equipmentId,
  }) async {
    try {
      final response = await _dio.delete(
        '/equipment/$equipmentId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // ─── USERS ───────────────────────────────────────────

  // Get User Profile
  static Future<Map<String, dynamic>> getUserProfile({
    required String userId,
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/users/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Search Users
  static Future<Map<String, dynamic>> searchUsers({
    required String query,
    required String token,
    String? role,
  }) async {
    try {
      String url = '/users/search?q=$query';
      if (role != null && role.isNotEmpty) {
        url += '&role=$role';
      }
      final response = await _dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get All Users
  static Future<Map<String, dynamic>> getAllUsers({
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/users/all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Follow User
  static Future<Map<String, dynamic>> followUser({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await _dio.put(
        '/users/follow/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Unfollow User
  static Future<Map<String, dynamic>> unfollowUser({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await _dio.put(
        '/users/unfollow/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get Followers
  static Future<Map<String, dynamic>> getFollowers({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await _dio.get(
        '/users/followers/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get Following
  static Future<Map<String, dynamic>> getFollowing({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await _dio.get(
        '/users/following/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }
  // ─── JOBS ────────────────────────────────────────────

  // Create Job
  static Future<Map<String, dynamic>> createJob({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post(
        '/jobs',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get All Jobs
  static Future<Map<String, dynamic>> getAllJobs({
    required String token,
    String? jobType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (jobType != null && jobType.isNotEmpty) {
        queryParams['jobType'] = jobType;
      }

      final response = await _dio.get(
        '/jobs',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get My Jobs
  static Future<Map<String, dynamic>> getMyJobs({required String token}) async {
    try {
      final response = await _dio.get(
        '/jobs/my',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Get Job By ID
  static Future<Map<String, dynamic>> getJobById({
    required String token,
    required String jobId,
  }) async {
    try {
      final response = await _dio.get(
        '/jobs/$jobId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Apply to Job
  static Future<Map<String, dynamic>> applyToJob({
    required String token,
    required String jobId,
  }) async {
    try {
      final response = await _dio.post(
        '/jobs/$jobId/apply',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Delete Job
  static Future<Map<String, dynamic>> deleteJob({
    required String token,
    required String jobId,
  }) async {
    try {
      final response = await _dio.delete(
        '/jobs/$jobId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }
}
