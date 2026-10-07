import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL for the SEMS C# backend.
final String kApiBaseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';

// ─── Token Storage ────────────────────────────────────────────────────────────
const _storage = FlutterSecureStorage();
const _tokenKey = 'sems-token';

class TokenStore {
  static Future<String?> get() => _storage.read(key: _tokenKey);
  static Future<void> set(String token) =>
      _storage.write(key: _tokenKey, value: token);
  static Future<void> clear() => _storage.delete(key: _tokenKey);
}

// ─── Dio Instance ─────────────────────────────────────────────────────────────
final Dio api = _createDio();

Dio _createDio() {
  final dio = Dio(BaseOptions(
    baseUrl: kApiBaseUrl,
    contentType: 'application/json',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Attach JWT token to every request.
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await TokenStore.get();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      // On 401, clear token (will be handled by auth provider).
      if (error.response?.statusCode == 401) {
        TokenStore.clear();
      }
      handler.next(error);
    },
  ));

  return dio;
}
