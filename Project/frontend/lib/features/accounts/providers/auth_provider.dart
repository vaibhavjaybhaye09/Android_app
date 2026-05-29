import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, this._storage);

  final AuthService _authService;
  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _emailKey = 'user_email';
  static const String _roleKey = 'user_role';
  static const String _idKey = 'user_id';

  bool _isLoading = false;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _accessTokenKey);
    final email = await _storage.read(key: _emailKey);
    final role = await _storage.read(key: _roleKey);
    final idStr = await _storage.read(key: _idKey);

    if (token == null || email == null) {
      return false;
    }

    _currentUser = UserModel(
      id: int.tryParse(idStr ?? '0') ?? 0,
      email: email,
      role: role ?? 'unassigned',
      accessToken: token,
      refreshToken: await _storage.read(key: _refreshTokenKey),
    );
    return true;
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final user = await _authService.login(email: email, password: password);
      _currentUser = user;
      await _persistUser(user);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<String> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    try {
      return await _authService.register(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setRole(String role) async {
    _setLoading(true);
    try {
      await _authService.setRole(role: role);
      if (_currentUser != null) {
        _currentUser = UserModel(
          id: _currentUser!.id,
          email: _currentUser!.email,
          role: role,
          accessToken: _currentUser!.accessToken,
          refreshToken: _currentUser!.refreshToken,
        );
        await _persistUser(_currentUser!);
        notifyListeners();
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    try {
      return await _authService.verifyOtp(email: email, otp: otp);
    } finally {
      _setLoading(false);
    }
  }

  Future<String> requestPasswordReset({
    required String email,
  }) async {
    _setLoading(true);
    try {
      return await _authService.requestPasswordReset(email: email);
    } finally {
      _setLoading(false);
    }
  }

  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      return await _authService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  Future<void> _persistUser(UserModel user) async {
    if (user.accessToken != null) {
      await _storage.write(key: _accessTokenKey, value: user.accessToken);
    }
    if (user.refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: user.refreshToken);
    }
    await _storage.write(key: _emailKey, value: user.email);
    await _storage.write(key: _roleKey, value: user.role);
    await _storage.write(key: _idKey, value: user.id.toString());
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
