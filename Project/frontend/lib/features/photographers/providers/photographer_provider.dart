import 'package:flutter/material.dart';
import '../../../models/photographer_model.dart';
import '../../../models/post_model.dart';
import '../../../models/service_model.dart';
import '../../../models/portfolio_item_model.dart';
import '../../../services/api_service.dart';

class PhotographerProvider extends ChangeNotifier {
  final ApiService _apiService;

  PhotographerProvider(this._apiService);

  List<PhotographerModel> _photographers = [];
  List<PostModel> _nearbyFeed = [];
  List<PostModel> _photographerPosts = [];
  List<ServiceModel> _photographerServices = [];
  List<PortfolioItemModel> _photographerPortfolio = [];
  bool _isLoading = false;
  String? _error;

  List<PhotographerModel> get photographers => _photographers;
  List<PostModel> get nearbyFeed => _nearbyFeed;
  List<PostModel> get photographerPosts => _photographerPosts;
  List<ServiceModel> get photographerServices => _photographerServices;
  List<PortfolioItemModel> get photographerPortfolio => _photographerPortfolio;
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
      // Also fetch services and portfolio for the same photographer
      await fetchPhotographerServices(id);
      await fetchPhotographerPortfolio(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPhotographerServices(int userId) async {
    try {
      final response = await _apiService.dioClient.dio.get('/api/auth/services/', queryParameters: {'user': userId});
      final List<dynamic> data = response.data;
      _photographerServices = data.map((json) => ServiceModel.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching services: $e");
    }
  }

  Future<void> fetchPhotographerPortfolio(int userId) async {
    try {
      final response = await _apiService.dioClient.dio.get('/api/auth/portfolio/', queryParameters: {'user': userId});
      final List<dynamic> data = response.data;
      _photographerPortfolio = data.map((json) => PortfolioItemModel.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching portfolio: $e");
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
