import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _kCompleted = 'onboarding.completed';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kCompleted) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCompleted, true);
  }

  /// Exposed so "Revoir le tutoriel" in Settings/About can reset it.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCompleted);
  }
}
