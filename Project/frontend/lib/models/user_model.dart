class UserModel {
  const UserModel({
    required this.email,
    required this.role,
    this.accessToken,
    this.refreshToken,
  });

  final String email;
  final String role;
  final String? accessToken;
  final String? refreshToken;

  factory UserModel.fromLoginResponse(
    Map<String, dynamic> json, {
    required String email,
  }) {
    return UserModel(
      email: email,
      role: (json['role'] ?? 'customer').toString(),
      accessToken: json['access']?.toString(),
      refreshToken: json['refresh']?.toString(),
    );
  }
}
