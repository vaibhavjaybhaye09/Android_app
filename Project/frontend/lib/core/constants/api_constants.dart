import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _computerIp = '192.168.1.6'; 

  static const String _webDefaultBaseUrl = 'http://localhost:8000';
  static const String _androidDefaultBaseUrl = 'http://$_computerIp:8000';

  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }
    return kIsWeb ? _webDefaultBaseUrl : _androidDefaultBaseUrl;
  }

  // Auth Endpoints (Matching api/auth/ in urls.py)
  static const String login = '/api/auth/login/';
  static const String register = '/api/auth/register/';
  static const String verifyOtp = '/api/auth/verify-otp/';
  static const String resendOtp = '/api/auth/resend-otp/';
  static const String logout = '/api/auth/logout/';
  static const String profile = '/api/auth/profile/';
  static const String changePassword = '/api/auth/change-password/';
  static const String forgotPassword = '/api/auth/forgot-password/';
  static const String resetPassword = '/api/auth/reset-password/';

  // Other Endpoints (Matching api/ in urls.py)
  static const String photographers = '/api/profiles/';
  static const String posts = '/api/posts/';
  static const String nearbyFeed = '/api/posts/nearby_feed/';
  static const String comments = '/api/comments/';
  static const String notifications = '/api/notifications/';
  static const String portfolio = '/api/portfolio/';
  static const String categories = '/api/categories/';
  static const String stories = '/api/stories/';
  static const String conversations = '/api/conversations/';
  static const String messages = '/api/messages/';
  static const String bookings = '/api/bookings/';
  static const String customerProfile = '/api/profile/';
  static const String search = '/api/profiles/search/';
}
