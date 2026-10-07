import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language provider — manages ES/EN translations, persisted to SharedPreferences.
/// Mirrors the web's LanguageContext.tsx.
class LanguageProvider extends ChangeNotifier {
  static const _key = 'sems-lang';
  String _lang = 'es';

  String get lang => _lang;
  bool get isEs => _lang == 'es';
  bool get isEn => _lang == 'en';

  LanguageProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    _lang = (saved == 'en') ? 'en' : 'es';
    notifyListeners();
  }

  Future<void> setLang(String l) async {
    _lang = (l == 'en') ? 'en' : 'es';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _lang);
  }

  Future<void> toggle() async {
    await setLang(_lang == 'es' ? 'en' : 'es');
  }

  /// Inline translation helper. Returns [es] if current language is Spanish, else [en].
  String t(String es, String en) => _lang == 'en' ? en : es;
}
