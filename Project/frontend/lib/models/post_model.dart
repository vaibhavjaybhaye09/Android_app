class PostModel {
  final int id;
  final String file;
  final String postType;
  final String? caption;
  final String? location;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByUser;
  final DateTime createdAt;
  final PhotographerLocation? photographerLocation;
  final Map<String, dynamic> photographer;

  PostModel({
    required this.id,
    required this.file,
    required this.postType,
    this.caption,
    this.location,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByUser,
    required this.createdAt,
    this.photographerLocation,
    required this.photographer,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int,
      file: json['file'] as String? ?? json['image'] as String? ?? '',
      postType: json['post_type'] as String? ?? 'image',
      caption: json['caption'] as String?,
      location: json['location'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLikedByUser: json['is_liked_by_user'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      photographerLocation: json['photographer_location'] != null
          ? PhotographerLocation.fromJson(json['photographer_location'] as Map<String, dynamic>)
          : null,
      photographer: json['photographer'] as Map<String, dynamic>,
    );
  }
}

class PhotographerLocation {
  final String city;
  final String area;
  final String pincode;

  PhotographerLocation({
    required this.city,
    required this.area,
    required this.pincode,
  });

  factory PhotographerLocation.fromJson(Map<String, dynamic> json) {
    return PhotographerLocation(
      city: json['city'] as String? ?? '',
      area: json['area'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
    );
  }
}
