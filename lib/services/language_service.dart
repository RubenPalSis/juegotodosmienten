
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService with ChangeNotifier {
  static const String _languageCodeKey = 'languageCode';
  Locale _appLocale = const Locale('es');

  LanguageService() {
    _loadLocale();
  }

  Locale get appLocale => _appLocale;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey) ?? 'es';
    _appLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> changeLanguage(Locale newLocale) async {
    if (_appLocale == newLocale) return;

    _appLocale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, newLocale.languageCode);
    // The UI will be updated by the consumer in the MaterialApp
    notifyListeners(); 
  }
}
