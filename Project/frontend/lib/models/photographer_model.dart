class PhotographerModel {
  final int id;
  final String name;
  final String email;
  final String? profileImage;
  final String? bio;
  final String specialty;
  final double rating;
  final double hourlyRate;
  final List<String> portfolio;

  PhotographerModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.bio,
    required this.specialty,
    required this.rating,
    required this.hourlyRate,
    this.portfolio = const [],
  });

  factory PhotographerModel.fromJson(Map<String, dynamic> json) {
    return PhotographerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImage: json['profile_image'] as String?,
      bio: json['bio'] as String?,
      specialty: json['specialty'] as String? ?? 'General',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      portfolio: (json['portfolio'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
