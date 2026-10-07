import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/features/auth/domain/entities/user.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_application_1/core/config/api.dart';

/// Auth provider — manages user session, login, register, and logout.
/// Mirrors the web's AuthContext.tsx.
class AuthProvider extends ChangeNotifier {
  static const _userKey = 'sems-user';

  User? _user;
  bool _loading = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _loading;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString(_userKey);
    final token = await TokenStore.get();

    if (rawUser != null && token != null) {
      try {
        _user = User.fromJson(jsonDecode(rawUser));
        notifyListeners();
      } catch (e) {
        // Ignore
      }
    }
  }

  Future<void> _persist(String token, User u) async {
    await TokenStore.set(token);
    final prefs = await SharedPreferences.getInstance();
    
    // Check if there's a custom name for this email
    final customName = prefs.getString('custom_name_${u.email}');
    if (customName != null && customName.isNotEmpty) {
      u = u.copyWith(fullName: customName);
    }
    
    await prefs.setString(_userKey, jsonEncode(u.toJson()));
    _user = u;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await AuthRepositoryImpl.login(email, password);
      await _persist(res.token, res.user);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle(String idToken) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await AuthRepositoryImpl.loginWithGoogle(idToken);
      await _persist(res.token, res.user);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await AuthRepositoryImpl.register(email, password);
      await _persist(res.token, res.user);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? fullName}) async {
    if (_user == null) return;
    final next = _user!.copyWith(fullName: fullName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(next.toJson()));
    if (fullName != null) {
      await prefs.setString('custom_name_${_user!.email}', fullName);
    }
    _user = next;
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthRepositoryImpl.logout();
    await TokenStore.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    _user = null;
    notifyListeners();
  }
}
