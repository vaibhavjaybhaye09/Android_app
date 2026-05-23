import 'package:flutter/material.dart';
import '../../../models/photographer_model.dart';
import '../../../models/post_model.dart';
import '../../../services/api_service.dart';

class PhotographerProvider extends ChangeNotifier {
  final ApiService _apiService;

  PhotographerProvider(this._apiService);

  List<PhotographerModel> _photographers = [];
  List<PostModel> _nearbyFeed = [];
  bool _isLoading = false;
  String? _error;

  List<PhotographerModel> get photographers => _photographers;
  List<PostModel> get nearbyFeed => _nearbyFeed;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPhotographers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _photographers = await _apiService.getPhotographers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyFeed() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<dynamic> data = await _apiService.getNearbyFeed();
      _nearbyFeed = data.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
