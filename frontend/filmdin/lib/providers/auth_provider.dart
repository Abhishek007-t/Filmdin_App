import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    final result = await ApiService.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );

    _isLoading = false;

    if (result['success']) {
      _token = result['data']['token'];
      _user = result['data']['user'];
      await _saveToken(_token!);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.login(email: email, password: password);

    _isLoading = false;

    if (result['success']) {
      _token = result['data']['token'];
      _user = result['data']['user'];
      await _saveToken(_token!);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({
    required String name,
    required String bio,
    required String location,
    required String role,
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

  // Save token to phone storage
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Logout
  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  // Check if already logged in
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    notifyListeners();
  }
}
