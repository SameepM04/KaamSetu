import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores and persists the app-wide light/dark preference.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider._();

  static final ThemeProvider _instance = ThemeProvider._();

  static ThemeProvider get instance => _instance;

  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);

    _mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'dark' : 'light');
  }
}