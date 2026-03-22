import 'package:flutter/material.dart';
import '../services/api_service.dart';

class JobProvider extends ChangeNotifier {
  List<dynamic> _jobs = [];
  bool _isLoading = false;
  String _selectedJobType = 'All';
  String? _errorMessage;

  List<dynamic> get jobs => _jobs;
  bool get isLoading => _isLoading;
  String get selectedJobType => _selectedJobType;
  String? get errorMessage => _errorMessage;

  // Fetch All Jobs
  Future<void> fetchAllJobs({
    required String token,
    String? jobType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.getAllJobs(
      token: token,
      jobType: jobType,
    );

    if (result['success']) {
      _jobs = (result['data']?['jobs'] as List<dynamic>?) ?? [];
    } else {
      _errorMessage = result['message'] ?? 'Failed to load jobs';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create Job
  Future<bool> createJob({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.createJob(
      token: token,
      data: data,
    );

    if (result['success']) {
      final createdJob = result['data']?['job'];
      if (createdJob != null) {
        _jobs.insert(0, createdJob);
      }
      notifyListeners();
      return true;
    }

    _errorMessage = result['message'] ?? 'Failed to create job';
    notifyListeners();
    return false;
  }

  // Apply to Job
  Future<bool> applyToJob({
    required String token,
    required String jobId,
  }) async {
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.applyToJob(
      token: token,
      jobId: jobId,
    );

    if (!result['success']) {
      _errorMessage = result['message'] ?? 'Failed to apply';
      notifyListeners();
    }

    return result['success'];
  }

  // Filter by Type
  void filterByType(String type) {
    _selectedJobType = type;
    notifyListeners();
  }
}