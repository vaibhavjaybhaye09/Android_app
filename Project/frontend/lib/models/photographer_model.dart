class PhotographerModel {
  final int id;
  final String name;
  final String email;
  final String? profileImage;
  final String? bio;
  final String specialty;
  final double rating;
  final double hourlyRate;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isVerified;
  final String? location;

  PhotographerModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.bio,
    required this.specialty,
    required this.rating,
    required this.hourlyRate,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isVerified = false,
    this.location,
  });

  factory PhotographerModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user data if it comes from the profile serializer
    final userData = json['user'] as Map<String, dynamic>?;
    
    return PhotographerModel(
      id: json['id'] as int,
      name: json['display_name'] ?? userData?['email']?.split('@')[0] ?? 'Photographer',
      email: userData?['email'] ?? '',
      profileImage: json['profile_picture'] as String?,
      bio: json['bio'] as String?,
      specialty: json['camera_details'] ?? 'Professional Photographer',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      hourlyRate: 50.0, // Default or map from a service price if available
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
      isVerified: json['is_verified_photographer'] as bool? ?? false,
      location: json['city'] != null ? "${json['city']}, ${json['area']}" : null,
    );
  }
}
