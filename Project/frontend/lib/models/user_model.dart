class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.accessToken,
    this.refreshToken,
  });

  final int id;
  final String email;
  final String role;
  final String? accessToken;
  final String? refreshToken;

  factory UserModel.fromLoginResponse(
    Map<String, dynamic> json, {
    required String email,
  }) {
    final userData = json['user'] as Map<String, dynamic>?;
    return UserModel(
      id: userData?['id'] ?? 0,
      email: email,
      role: (userData?['role'] ?? 'unassigned').toString(),
      accessToken: json['access']?.toString(),
      refreshToken: json['refresh']?.toString(),
    );
  }
}
