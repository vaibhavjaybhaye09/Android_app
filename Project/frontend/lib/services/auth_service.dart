import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService(this._dioClient);

  final DioClient _dioClient;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      return UserModel.fromLoginResponse(response.data, email: email);
    } on DioException catch (error) {
      throw AuthException(_extractMessage(error));
    }
  }

  Future<String> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );

      return response.data['message']?.toString() ?? 'OTP sent to email';
    } on DioException catch (error) {
      throw AuthException(_extractMessage(error));
    }
  }

  Future<String> setRole({
    required String role,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/auth/profile/set_role/',
        data: {'role': role},
      );
      return response.data['message']?.toString() ?? 'Role set successfully';
    } on DioException catch (error) {
      throw AuthException(_extractMessage(error));
    }
  }

  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.verifyOtp,
        data: {
          'email': email,
          'otp': otp,
        },
      );

      return response.data['message']?.toString() ??
          'Email verified successfully';
    } on DioException catch (error) {
      throw AuthException(_extractMessage(error));
    }
  }

  Future<String> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
      return response.data['message']?.toString() ?? 'Password reset email sent';
    } on DioException catch (error) {
      throw AuthException(_extractMessage(error));
    }
  }

  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.resetPassword,
        data: {
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        },
      );
      return response.data['message']?.toString() ?? 'Password reset successful';
    } on DioException catch (error) {
      throw AuthException(_extractMessage(error));
    }
  }

  Future<String> logout() async {
    try {
      final response = await _dioClient.dio.post(ApiConstants.logout);
      return response.data['message']?.toString() ?? 'Logged out';
    } on DioException catch (error) {
      throw AuthException(_extractMessage(error));
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.profile);
      return response.data;
    } on DioException catch (error) {
      throw AuthException(_extractMessage(error));
    }
  }

  String _extractMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      if (data['error'] != null) {
        return data['error'].toString();
      }

      if (data['message'] != null) {
        return data['message'].toString();
      }

      final firstEntry = data.entries.firstWhere(
        (entry) => entry.value != null,
        orElse: () => const MapEntry('error', 'Something went wrong'),
      );

      final value = firstEntry.value;
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }

      return value.toString();
    }

    return error.message ?? 'Something went wrong';
  }
}
