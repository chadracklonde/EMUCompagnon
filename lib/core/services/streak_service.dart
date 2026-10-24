import 'package:shared_preferences/shared_preferences.dart';

class StreakInfo {
  final int current;
  final int longest;
  const StreakInfo({required this.current, required this.longest});
}

/// Tracks how many consecutive calendar days in a row the user has opened
/// the app — a purely local "streak" (no account, no server, nothing to
/// sync), consistent with the app's offline-first philosophy.
///
/// Storage is plain SharedPreferences, like [ReadingPlanService], since
/// this is a handful of scalar values rather than relational data.
class StreakService {
  static const _kLastActiveDate = 'streak.lastActiveDate';
  static const _kCurrentStreak = 'streak.current';
  static const _kLongestStreak = 'streak.longest';

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Call once per app session (e.g. on home screen init). Idempotent
  /// within a single calendar day: opening the app many times the same
  /// day never double-counts. Returns the up-to-date streak after
  /// applying today's visit.
  static Future<StreakInfo> recordVisitToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final lastDate = prefs.getString(_kLastActiveDate);
    var current = prefs.getInt(_kCurrentStreak) ?? 0;
    var longest = prefs.getInt(_kLongestStreak) ?? 0;

    if (lastDate == todayKey) {
      return StreakInfo(current: current, longest: longest);
    }

    if (lastDate != null) {
      final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));
      current = (lastDate == yesterdayKey) ? current + 1 : 1;
    } else {
      current = 1; // first-ever visit
    }

    if (current > longest) longest = current;

    await prefs.setString(_kLastActiveDate, todayKey);
    await prefs.setInt(_kCurrentStreak, current);
    await prefs.setInt(_kLongestStreak, longest);

    return StreakInfo(current: current, longest: longest);
  }

  static Future<StreakInfo> getCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    return StreakInfo(
      current: prefs.getInt(_kCurrentStreak) ?? 0,
      longest: prefs.getInt(_kLongestStreak) ?? 0,
    );
  }
}
