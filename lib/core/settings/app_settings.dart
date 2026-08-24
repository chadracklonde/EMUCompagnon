import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds user-adjustable display preferences and persists them locally.
/// Wrapped around the app via [ChangeNotifierProvider] in main.dart, so any
/// widget can read/watch it with `context.watch<AppSettings>()`.
class AppSettings extends ChangeNotifier {
  static const _kThemeMode = 'settings.themeMode'; // 'system' | 'light' | 'dark'
  static const _kTextScale = 'settings.textScale';
  static const _kLineHeightScale = 'settings.lineHeightScale';

  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = 1.0; // multiplier applied on top of base font sizes
  double _lineHeightScale = 1.0; // multiplier applied on top of base line height

  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;
  double get lineHeightScale => _lineHeightScale;

  static const double minTextScale = 0.8;
  static const double maxTextScale = 1.6;
  static const double minLineHeightScale = 0.9;
  static const double maxLineHeightScale = 1.6;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_kThemeMode);
    _themeMode = switch (modeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _textScale = prefs.getDouble(_kTextScale) ?? 1.0;
    _lineHeightScale = prefs.getDouble(_kLineHeightScale) ?? 1.0;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  Future<void> setTextScale(double value) async {
    _textScale = value.clamp(minTextScale, maxTextScale);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTextScale, _textScale);
  }

  Future<void> setLineHeightScale(double value) async {
    _lineHeightScale = value.clamp(minLineHeightScale, maxLineHeightScale);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLineHeightScale, _lineHeightScale);
  }

  Future<void> resetToDefaults() async {
    await setThemeMode(ThemeMode.system);
    await setTextScale(1.0);
    await setLineHeightScale(1.0);
  }
}
