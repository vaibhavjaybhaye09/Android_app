import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  final ApiService _apiService;
  Map<String, dynamic>? _profileData;
  List<dynamic> _skills = [];
  bool _isLoading = false;

  ProfileProvider(this._apiService);

  Map<String, dynamic>? get profileData => _profileData;
  List<dynamic> get skills => _skills;
  bool get isLoading => _isLoading;

  Future<void> fetchProfile(String _) async {
    _isLoading = true;
    notifyListeners();
    try {
      _profileData = await _apiService.getMyProfile();
      _skills = await _apiService.getSkills();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      _profileData = await _apiService.updateProfile(data);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
