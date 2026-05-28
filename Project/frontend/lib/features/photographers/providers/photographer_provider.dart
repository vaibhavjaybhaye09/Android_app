import 'package:flutter/material.dart';
import '../../../models/photographer_model.dart';
import '../../../models/post_model.dart';
import '../../../services/api_service.dart';

class PhotographerProvider extends ChangeNotifier {
  final ApiService _apiService;

  PhotographerProvider(this._apiService);

  List<PhotographerModel> _photographers = [];
  List<PostModel> _nearbyFeed = [];
  List<PostModel> _photographerPosts = [];
  bool _isLoading = false;
  String? _error;

  List<PhotographerModel> get photographers => _photographers;
  List<PostModel> get nearbyFeed => _nearbyFeed;
  List<PostModel> get photographerPosts => _photographerPosts;
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

  Future<void> fetchPhotographerPosts(int id) async {
    _isLoading = true;
    _photographerPosts = [];
    notifyListeners();
    try {
      _photographerPosts = await _apiService.getPhotographerPosts(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int postId) async {
    try {
      await _apiService.likePost(postId);
      // Update local state if needed for immediate feedback
      final index = _nearbyFeed.indexWhere((p) => p.id == postId);
      if (index != -1) {
        // We'd need to copy the model to update it since it's final
        // For now, re-fetching or optimistic UI is better
      }
    } catch (e) {
      debugPrint("Error liking post: $e");
    }
  }
}
