class PortfolioItemModel {
  final int? id;
  final String title;
  final String? image;
  final String description;
  final DateTime? createdAt;
  final int? userId;

  PortfolioItemModel({
    this.id,
    required this.title,
    this.image,
    required this.description,
    this.createdAt,
    this.userId,
  });

  factory PortfolioItemModel.fromJson(Map<String, dynamic> json) {
    return PortfolioItemModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      image: json['image'] as String?,
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      userId: json['user'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      if (userId != null) 'user': userId,
    };
  }
}
