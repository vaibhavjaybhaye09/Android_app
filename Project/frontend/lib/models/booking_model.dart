import 'photographer_model.dart';

class BookingModel {
  final int id;
  final PhotographerModel photographer;
  final String date;
  final String status;
  final double totalPrice;
  final String? notes;

  BookingModel({
    required this.id,
    required this.photographer,
    required this.date,
    required this.status,
    required this.totalPrice,
    this.notes,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int,
      photographer: PhotographerModel.fromJson(json['photographer'] as Map<String, dynamic>),
      date: json['date'] as String,
      status: json['status'] as String,
      totalPrice: (json['total_price'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}
