class ServiceModel {
  final int? id;
  final String title;
  final String description;
  final double price;
  final String category;
  final int? userId;

  ServiceModel({
    this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    this.userId,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      price: double.parse(json['price'].toString()),
      category: json['category'] as String,
      userId: json['user'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      if (userId != null) 'user': userId,
    };
  }
}
