import 'package:chatappui/core/constants/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeColorOption { blue, emerald, sunset, violet }

extension ThemeColorOptionX on ThemeColorOption {
  String get label {
    switch (this) {
      case ThemeColorOption.blue:
        return 'Blue';
      case ThemeColorOption.emerald:
        return 'Emerald';
      case ThemeColorOption.sunset:
        return 'Sunset';
      case ThemeColorOption.violet:
        return 'Violet';
    }
  }

  Color get seedColor {
    switch (this) {
      case ThemeColorOption.blue:
        return const Color(0xFF2563EB);
      case ThemeColorOption.emerald:
        return const Color(0xFF059669);
      case ThemeColorOption.sunset:
        return const Color(0xFFE76F51);
      case ThemeColorOption.violet:
        return const Color(0xFF7C3AED);
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _themeColorKey = 'theme_color';
  static const String _fontScaleKey = 'font_scale';

  AppThemeOption _themeMode = AppThemeOption.light;
  ThemeColorOption _themeColor = ThemeColorOption.blue;
  double _fontScale = 1.0;

  AppThemeOption get themeMode => _themeMode;
  ThemeColorOption get themeColor => _themeColor;
  double get fontScale => _fontScale;
  bool get isDarkMode => _themeMode == AppThemeOption.dark;

  ThemeData get themeData => AppThemes.buildTheme(
        themeMode: _themeMode,
        seedColor: _themeColor.seedColor,
      );

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(_themeModeKey);
    final savedThemeColor = prefs.getString(_themeColorKey);
    final savedFontScale = prefs.getDouble(_fontScaleKey);

    _themeMode = AppThemeOption.values.firstWhere(
      (option) => option.name == savedThemeMode,
      orElse: () => AppThemeOption.light,
    );
    _themeColor = ThemeColorOption.values.firstWhere(
      (option) => option.name == savedThemeColor,
      orElse: () => ThemeColorOption.blue,
    );
    _fontScale = (savedFontScale ?? 1.0).clamp(0.85, 1.40).toDouble();
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeOption mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> toggleDarkMode() async {
    await setThemeMode(
      isDarkMode ? AppThemeOption.light : AppThemeOption.dark,
    );
  }

  Future<void> setThemeColor(ThemeColorOption color) async {
    _themeColor = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeColorKey, color.name);
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value.clamp(0.85, 1.40).toDouble();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, _fontScale);
  }
}
