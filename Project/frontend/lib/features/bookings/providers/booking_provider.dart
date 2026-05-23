import 'package:flutter/material.dart';
import '../../../models/booking_model.dart';
import '../../../services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  final ApiService _apiService;

  BookingProvider(this._apiService);

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bookings = await _apiService.getMyBookings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBooking({
    required int photographerId,
    required String date,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.createBooking(
        photographerId: photographerId,
        date: date,
        notes: notes,
      );
      await fetchMyBookings(); // Refresh bookings list
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
