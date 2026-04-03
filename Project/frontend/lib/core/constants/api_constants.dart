import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _webDefaultBaseUrl = 'http://127.0.0.1:8000/api';
  static const String _androidDefaultBaseUrl = 'http://10.0.2.2:8000/api';

  // Override with:
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000/api
  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    return kIsWeb ? _webDefaultBaseUrl : _androidDefaultBaseUrl;
  }

  static const String login = '/accounts/login/';
  static const String register = '/accounts/register/';
  static const String verifyOtp = '/accounts/verify-otp/';
}
