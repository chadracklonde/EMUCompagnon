import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';
import 'reading_plan_service.dart';

/// Keeps the daily reminder's text in step with the reading plan, so it
/// says what to read ("Lecture du jour : Genèse 14–25") rather than a
/// generic nudge.
///
/// A scheduled notification cannot compute its text when it fires, so the
/// text is refreshed each time the app starts and each time reading
/// progress or the plan changes. It therefore always names the next
/// portion to read as of the last time the app was used.
class ReadingReminder {
  // Same keys as AppSettings, read directly so this works without a widget.
  static const _kEnabled = 'settings.notificationsEnabled';
  static const _kHour = 'settings.notificationHour';
  static const _kMinute = 'settings.notificationMinute';

  /// Text of the reminder for [plan] as it stands.
  static String bodyFor(ReadingPlan plan) {
    final next = plan.nextDay;
    if (next == null) return NotificationService.defaultReminderBody;
    return 'Lecture du jour : ${next.label}.';
  }

  /// Re-schedules the reminder with up-to-date text, if it is enabled.
  /// Never throws: a reminder problem must not get in the way of reading.
  static Future<void> sync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kEnabled) != true) return;
      final plan = await ReadingPlanService.getPlan();
      await NotificationService.scheduleDaily(
        hour: prefs.getInt(_kHour) ?? 7,
        minute: prefs.getInt(_kMinute) ?? 0,
        body: bodyFor(plan),
      );
    } catch (_) {}
  }
}
