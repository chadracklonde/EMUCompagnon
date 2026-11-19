import 'package:shared_preferences/shared_preferences.dart';

/// What the "Culte du dimanche" screen remembers.
class WorshipService {
  static const listKey = 'worship.hymnListId';

  /// Id of the hymn list chosen for the service, if any.
  static Future<String?> chosenListId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(listKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> chooseList(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(listKey, id);
  }

  /// The day the service screen prepares: today on a Sunday, otherwise
  /// the coming Sunday.
  static DateTime serviceDay(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return today.add(Duration(days: (DateTime.sunday - today.weekday) % 7));
  }
}
