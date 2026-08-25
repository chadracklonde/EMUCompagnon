import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds user-adjustable display preferences and persists them locally.
/// Wrapped around the app via [ChangeNotifierProvider] in main.dart, so any
/// widget can read/watch it with `context.watch<AppSettings>()`.
class AppSettings extends ChangeNotifier {
  static const _kThemeMode = 'settings.themeMode'; // 'system' | 'light' | 'dark'
  static const _kTextScale = 'settings.textScale';
  static const _kLineHeightScale = 'settings.lineHeightScale';
  static const _kFontFamily = 'settings.fontFamily'; // 'system' | 'serif' | 'sansSerif'
  static const _kLocale = 'settings.locale'; // 'fr' | 'sw'
  static const _kNotificationsEnabled = 'settings.notificationsEnabled';
  static const _kNotificationHour = 'settings.notificationHour';
  static const _kNotificationMinute = 'settings.notificationMinute';
  static const _kBibleVersion = 'settings.bibleVersion';

  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = 1.0;
  double _lineHeightScale = 1.0;
  String _fontFamily = 'system';
  String _locale = 'fr';
  bool _notificationsEnabled = false;
  int _notificationHour = 7;
  int _notificationMinute = 0;
  String _bibleVersion = 'LSG1910';

  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;
  double get lineHeightScale => _lineHeightScale;
  String get fontFamily => _fontFamily;
  String get locale => _locale;
  bool get notificationsEnabled => _notificationsEnabled;
  int get notificationHour => _notificationHour;
  int get notificationMinute => _notificationMinute;
  String get bibleVersion => _bibleVersion;

  /// Maps the stored preference key to an actual Flutter font family string.
  /// 'serif'/'sans-serif' are generic families Skia resolves via platform
  /// font matching — no bundled font assets required.
  String? get resolvedFontFamily => switch (_fontFamily) {
        'serif' => 'serif',
        'sansSerif' => 'sans-serif',
        _ => null, // null = theme default (Roboto-ish on Android, SF on iOS)
      };

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
    _fontFamily = prefs.getString(_kFontFamily) ?? 'system';
    _locale = prefs.getString(_kLocale) ?? 'fr';
    _notificationsEnabled = prefs.getBool(_kNotificationsEnabled) ?? false;
    _notificationHour = prefs.getInt(_kNotificationHour) ?? 7;
    _notificationMinute = prefs.getInt(_kNotificationMinute) ?? 0;
    _bibleVersion = prefs.getString(_kBibleVersion) ?? 'LSG1910';
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

  Future<void> setFontFamily(String value) async {
    _fontFamily = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFontFamily, value);
  }

  Future<void> setLocale(String value) async {
    _locale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, value);
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    _notificationHour = hour;
    _notificationMinute = minute;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kNotificationHour, hour);
    await prefs.setInt(_kNotificationMinute, minute);
  }

  Future<void> setBibleVersion(String code) async {
    _bibleVersion = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBibleVersion, code);
  }

  Future<void> resetToDefaults() async {
    await setThemeMode(ThemeMode.system);
    await setTextScale(1.0);
    await setLineHeightScale(1.0);
    await setFontFamily('system');
  }
}
