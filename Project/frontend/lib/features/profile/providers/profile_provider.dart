import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  ProfileProvider(this._apiService);

  final ApiService _apiService;
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;

  Map<String, dynamic>? get profileData => _profileData;
  bool get isLoading => _isLoading;

  Future<void> fetchProfile(String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profileData = await _apiService.getMyProfile(role);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(String role, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profileData = await _apiService.updateProfile(role, data);
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
