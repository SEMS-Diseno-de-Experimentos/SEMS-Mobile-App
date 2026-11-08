import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL for the SEMS C# backend.
String get kApiBaseUrl {
  try {
    if (dotenv.isInitialized) {
      final url = dotenv.env['API_URL'];
      if (url != null && url.isNotEmpty) return url;
    }
  } catch (_) {}
  return 'http://localhost:8080';
}

// ─── Token Storage ────────────────────────────────────────────────────────────
const _storage = FlutterSecureStorage();
const _tokenKey = 'sems-token';

class TokenStore {
  static String? _cachedToken;

  static Future<String?> get() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) return _cachedToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_tokenKey);
      if (_cachedToken != null && _cachedToken!.isNotEmpty) return _cachedToken;
    } catch (_) {}
    try {
      _cachedToken = await _storage.read(key: _tokenKey);
      return _cachedToken;
    } catch (_) {
      return _cachedToken;
    }
  }

  static Future<void> set(String token) async {
    _cachedToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {}
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {}
  }

  static Future<void> clear() async {
    _cachedToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {}
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }
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

  // Attach JWT token and ensure fresh baseUrl to every request.
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      options.baseUrl = kApiBaseUrl;
      final token = await TokenStore.get();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        TokenStore.clear();
      }
      handler.next(error);
    },
  ));

  return dio;
}
