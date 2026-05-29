import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';

class DioClient {
  late Dio dio;
  static const storage = FlutterSecureStorage();
  static bool _isRefreshing = false;
  static final _refreshCompleter = Completer<String?>();

  DioClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    // Add token interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Handle 401 and token refresh
          if (e.response?.statusCode == 401) {
            try {
              final refreshToken = await storage.read(key: 'refresh_token');
              if (refreshToken != null) {
                final newToken = await _refreshToken(refreshToken);
                if (newToken != null) {
                  // Retry the failed request with new token
                  final opts = RequestOptions(
                    method: e.requestOptions.method,
                    path: e.requestOptions.path,
                    baseUrl: e.requestOptions.baseUrl,
                    headers: e.requestOptions.headers,
                    data: e.requestOptions.data,
                    queryParameters: e.requestOptions.queryParameters,
                  );
                  opts.headers['Authorization'] = 'Bearer $newToken';
                  return handler.resolve(await dio.fetch(opts));
                }
              }
            } catch (ex) {
              // Token refresh failed, let the original error propagate
            }
          }
          return handler.next(e);
        },
      ),
    );

    // Add logging interceptor for development
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Future<String?> _refreshToken(String refreshToken) async {
    if (_isRefreshing) {
      return _refreshCompleter.future;
    }

    _isRefreshing = true;
    try {
      final response = await Dio().post(
        '${ApiConstants.baseUrl}/api/token/refresh/',
        data: {'refresh': refreshToken},
        options: Options(
          contentType: 'application/json',
        ),
      );

      final newAccessToken = response.data['access'];
      if (newAccessToken != null) {
        await storage.write(key: 'access_token', value: newAccessToken);
        _refreshCompleter.complete(newAccessToken);
        return newAccessToken;
      }
    } catch (e) {
      _refreshCompleter.complete(null);
      // Clear tokens on refresh failure
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
    } finally {
      _isRefreshing = false;
    }
    return null;
  }
}
