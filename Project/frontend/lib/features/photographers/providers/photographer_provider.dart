import 'package:flutter/material.dart';
import '../../../models/photographer_model.dart';
import '../../../services/api_service.dart';

class PhotographerProvider extends ChangeNotifier {
  final ApiService _apiService;

  PhotographerProvider(this._apiService);

  List<PhotographerModel> _photographers = [];
  bool _isLoading = false;
  String? _error;

  List<PhotographerModel> get photographers => _photographers;
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
}
