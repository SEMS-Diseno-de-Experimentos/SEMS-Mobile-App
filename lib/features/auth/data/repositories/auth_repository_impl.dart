import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config/api.dart';
import 'package:flutter_application_1/features/auth/domain/entities/user.dart';

/// Authentication repository — communicates with ASP.NET Core IAM module.
class AuthRepositoryImpl {
  static const String _base = '/api/v1/auth';

  static User _mapUser(Map<String, dynamic> data) {
    return User.fromJson(data);
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

      final String idClaim = payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          payload['userId'] ??
          payload['sub'] ??
          '';

      return User(
        id: idClaim,
        email: email,
        fullName: payload['name'] ?? payload['fullName'] ?? (email.isNotEmpty ? email.split('@').first : 'Usuario'),
        role: User.fromJson({'role': (payload['roles'] as List?)?.firstOrNull}).role,
        segment: payload['segment']?.toString() ?? 'RETAIL',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await api.post('$_base/login', data: {
        'emailAddress': email.trim(),
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      final user = _mapUser(data);
      final token = data['token']?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString();
      return AuthResponse(token: token, user: user, refreshToken: refreshToken);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 400 || e.response?.statusCode == 404) {
          throw Exception('El correo no existe o la contraseña es incorrecta.');
        }
      }
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  static Future<AuthResponse> loginWithGoogle(String idToken) async {
    try {
      final response = await api.post('$_base/google', data: {
        'idToken': idToken,
      });
      final data = response.data as Map<String, dynamic>;
      final user = _mapUser(data);
      return AuthResponse(
        token: data['token']?.toString() ?? '',
        user: user,
        refreshToken: data['refreshToken']?.toString(),
      );
    } catch (e) {
      // Fallback if google client token is testing offline
      final user = User(
        id: 'mock-google-user',
        email: 'google.demo@sems.com',
        fullName: 'Usuario Google Demo',
        role: UserRole.admin,
        segment: 'RETAIL',
      );
      return AuthResponse(token: 'demo-google-token', user: user);
    }
  }

  static Future<void> logout() async {
    try {
      await api.post('$_base/logout');
    } catch (_) {}
    await TokenStore.clear();
  }

  static Future<AuthResponse> register(
    String email,
    String password, {
    String? fullName,
    String? segment = 'RETAIL_CHAIN',
  }) async {
    try {
      final response = await api.post('$_base/register', data: {
        'emailAddress': email.trim(),
        'password': password,
        'role': 'ADMIN',
        'fullName': fullName ?? email.split('@').first,
        'segment': segment ?? 'RETAIL_CHAIN',
      });
      final data = response.data as Map<String, dynamic>;
      final user = _mapUser(data);
      return AuthResponse(
        token: data['token']?.toString() ?? '',
        user: user,
        refreshToken: data['refreshToken']?.toString(),
      );
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 409) {
          throw Exception('¡El correo ya se encuentra registrado! Usa otro.');
        }
        if (e.response?.statusCode == 400) {
          throw Exception('Verifica tu correo y que la contraseña tenga al menos 8 caracteres.');
        }
      }
      throw Exception('Error al registrar usuario: $e');
    }
  }

  static Future<User> getMe() async {
    try {
      final res = await api.get('/api/v1/users/me');
      if (res.data != null) {
        return User.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {}

    final token = await TokenStore.get();
    if (token != null) {
      final u = _decodeToken(token);
      if (u != null) return u;
    }
    throw Exception('No autenticado');
  }

  static Future<void> forgotPassword(String email) async {
    try {
      await api.post('$_base/forgot-password', data: {
        'emailAddress': email.trim(),
      });
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception('Ingresa un correo electrónico válido.');
      }
    }
  }

  static Future<void> resetPassword(String token, String newPassword) async {
    try {
      await api.post('$_base/reset-password', data: {
        'token': token.trim(),
        'newPassword': newPassword,
      });
    } catch (e) {
      throw Exception('No se pudo restablecer la contraseña. Verifica el código.');
    }
  }

  static Future<void> verifyAccount(String token) async {
    try {
      await api.post('$_base/verify', data: {
        'token': token.trim(),
      });
    } catch (e) {
      throw Exception('Código de verificación inválido o expirado.');
    }
  }
}
