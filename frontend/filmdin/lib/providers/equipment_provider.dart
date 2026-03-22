import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EquipmentProvider extends ChangeNotifier {
  List<dynamic> _equipment = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';

  List<dynamic> get equipment => _equipment;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;

  Future<void> fetchAllEquipment({required String token}) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.getAllEquipment(
      token: token,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );

    if (result['success']) {
      _equipment = result['data']['equipment'] as List<dynamic>;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyEquipment({required String token}) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.getMyEquipment(token: token);

    if (result['success']) {
      _equipment = result['data']['equipment'] as List<dynamic>;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addEquipment({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.listEquipment(
      token: token,
      data: data,
    );

    _isLoading = false;

    if (result['success']) {
      final createdEquipment = result['data']['equipment'];
      if (createdEquipment != null) {
        _equipment.insert(0, createdEquipment);
      }
      notifyListeners();
      return true;
    }

    notifyListeners();
    return false;
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
}
