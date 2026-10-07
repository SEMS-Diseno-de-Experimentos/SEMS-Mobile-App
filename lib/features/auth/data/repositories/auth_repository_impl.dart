import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config/api.dart';
import 'package:flutter_application_1/core/utils/demo_seeder.dart';
import 'package:flutter_application_1/features/auth/domain/entities/user.dart';
/// Authentication service — mirrors the web's auth.service.ts.
class AuthRepositoryImpl {
  static const String _base = '/api/v1/auth';

  static User _mapUser(Map<String, dynamic> data) {
    return User(
      id: data['userId']?.toString() ?? '',
      email: data['emailAddress']?.toString() ?? '',
      fullName: _displayNameFromEmail(data['emailAddress']?.toString() ?? ''),
      role: User.fromJson({'role': (data['roles'] as List?)?.first}).role,
    );
  }

  static String _displayNameFromEmail(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) return 'Usuario';
    return local[0].toUpperCase() + local.substring(1);
  }

  static User? _decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      String normalized = parts[1];
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      final email = payload['email'] ?? payload['emailAddress'] ?? '';
      
      // Look for the standard C# ClaimTypes.NameIdentifier
      final String idClaim = payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] 
          ?? payload['userId'] 
          ?? payload['sub'] 
          ?? '';

      return User(
        id: idClaim,
        email: email,
        fullName: _displayNameFromEmail(email),
        role: User.fromJson({'role': (payload['roles'] as List?)?.first}).role,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await api.post('$_base/login', data: {
        'emailAddress': email,
        'password': password,
      });
      final data = response.data;
      final user = _mapUser(data);
      return AuthResponse(token: data['token'], user: user);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 400 || e.response?.statusCode == 404) {
          throw Exception('El correo no existe o la contraseña es incorrecta.');
        }
      }
      throw Exception('Failed to login: $e');
    }
  }

  static Future<AuthResponse> loginWithGoogle(String idToken) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    final user = User(
      id: 'mock-user-id',
      email: 'demo@google.com',
      fullName: 'Demo Google',
      role: UserRole.admin,
    );
    return AuthResponse(token: 'mock-jwt-token', user: user);
  }

  static Future<void> logout() async {
    // Just mock
  }

  static Future<AuthResponse> register(
    String email,
    String password,
  ) async {
    try {
      final response = await api.post('$_base/register', data: {
        'emailAddress': email,
        'password': password,
      });
      final data = response.data;
      final user = _mapUser(data);
      return AuthResponse(token: data['token'], user: user);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 409) {
          throw Exception('¡YA EXISTE UN EMAIL ASÍ! Por favor, usa otro.');
        }
        if (e.response?.statusCode == 400) {
          throw Exception('Verifica tu correo y que la contraseña tenga al menos 8 caracteres.');
        }
      }
      throw Exception('Failed to register: $e');
    }
  }

  static Future<User> getMe() async {
    // There is no /me endpoint in this specific setup, but we can decode the token or
    // fetch the user profile if needed. We'll return a basic user decoded from token for now
    // or simulate an endpoint fetch.
    final token = await TokenStore.get();
    if (token != null) {
      final u = _decodeToken(token);
      if (u != null) return u;
    }
    throw Exception('Not authenticated');
  }

  static Future<void> forgotPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Ingresa un correo electrónico válido.');
    }
  }

  static Future<void> resetPassword(String token, String newPassword) async {
    await Future.delayed(const Duration(seconds: 1));
    if (token != '726747') {
      throw Exception('Código de recuperación inválido o expirado.');
    }
    if (newPassword.length < 6) {
      throw Exception('La nueva contraseña debe tener al menos 6 caracteres.');
    }
  }

  static Future<void> verifyAccount(String token) async {
    await Future.delayed(const Duration(seconds: 1));
    if (token != '726747') {
      throw Exception('Código inválido.');
    }
  }
}
