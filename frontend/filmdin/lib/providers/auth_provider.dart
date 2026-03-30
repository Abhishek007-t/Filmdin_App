import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;

  Future<bool> _loadBackendUser() async {
    if (_token == null || _token!.isEmpty) {
      return false;
    }

    final result = await ApiService.getMyStats(token: _token!);
    if (result['success'] != true) {
      _errorMessage = result['message'] ?? 'Failed to load profile';
      return false;
    }

    final statsUser = result['data']?['user'] as Map<String, dynamic>?;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (statsUser != null) {
      _user = {
        ...statsUser,
        'id': (statsUser['id'] ?? statsUser['_id'])?.toString(),
        '_id': (statsUser['_id'] ?? statsUser['id'])?.toString(),
        'firebaseUid': firebaseUser?.uid,
        'email': firebaseUser?.email ?? statsUser['email'],
      };
    }

    return true;
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await credential.user?.updateDisplayName(name);
      _token = await credential.user?.getIdToken(true);

      if (_token == null || _token!.isEmpty) {
        _errorMessage = 'Unable to get Firebase session token';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final syncResult = await ApiService.updateProfile(
        token: _token!,
        name: name,
        bio: '',
        location: '',
        role: role,
      );

      if (syncResult['success'] != true) {
        _errorMessage = syncResult['message'] ?? 'Failed to sync user profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final loaded = await _loadBackendUser();
      _isLoading = false;
      notifyListeners();
      return loaded;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Firebase authentication failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to register';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      _token = await credential.user?.getIdToken(true);
      final loaded = await _loadBackendUser();

      _isLoading = false;
      notifyListeners();
      return loaded;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Invalid credentials';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to login';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Forgot password
  Future<bool> forgotPassword({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Failed to send reset email';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to send reset email';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword({
    required String token,
    required String password,
  }) async {
    _errorMessage = 'Use the reset link sent to your email to set a new password';
    notifyListeners();
    return false;
  }

  // Update profile
  Future<bool> updateProfile({
    required String name,
    required String bio,
    required String location,
    required String role,
    String? profilePhotoPath,
  }) async {
    if (_token == null || _token!.isEmpty) {
      _errorMessage = 'User is not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.updateProfile(
        token: _token!,
        name: name,
        bio: bio,
        location: location,
        role: role,
        profilePhotoPath: profilePhotoPath,
      );

      _isLoading = false;

      if (result['success']) {
        final updatedUser =
            result['data']?['user'] as Map<String, dynamic>? ??
            <String, dynamic>{};

        _user = {
          ...?_user,
          ...updatedUser,
          'name': name,
          'bio': bio,
          'location': location,
          'role': role,
        };

        if (_user?['_id'] == null && _user?['id'] != null) {
          _user?['_id'] = _user?['id'];
        }
        if (_user?['id'] == null && _user?['_id'] != null) {
          _user?['id'] = _user?['_id'];
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to update profile';
        notifyListeners();
        return false;
      }
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Failed to update profile';
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _token = null;
    _user = null;
    notifyListeners();
  }

  // Check if already logged in
  Future<void> checkLoginStatus() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      _token = null;
      _user = null;
      notifyListeners();
      return;
    }

    _token = await firebaseUser.getIdToken(true);
    await _loadBackendUser();
    notifyListeners();
  }
}
