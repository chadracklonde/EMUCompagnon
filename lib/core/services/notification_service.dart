import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Schedules a daily local reminder ("Verset du jour" / reading nudge).
///
/// Timezone note: rather than depending on an extra plugin to detect the
/// device's IANA timezone name, this computes the target notification
/// instant from the device's own local `DateTime` (which already knows
/// its UTC offset) and schedules it in the UTC timezone frame. This
/// fires at the correct local wall-clock time without needing timezone
/// lookups — the one caveat is that a region observing DST would drift
/// by an hour twice a year, which does not apply to DRC (no DST).
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _dailyReminderId = 1001;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    await init();
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<DarwinFlutterLocalNotificationsPlugin>();

    bool granted = true;
    if (androidImpl != null) {
      granted = await androidImpl.requestNotificationsPermission() ?? true;
    }
    if (iosImpl != null) {
      granted = await iosImpl.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    }
    return granted;
  }

  static Future<void> scheduleDaily({required int hour, required int minute}) async {
    await init();

    final now = DateTime.now();
    var scheduledLocal = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledLocal.isBefore(now)) {
      scheduledLocal = scheduledLocal.add(const Duration(days: 1));
    }
    final scheduledUtc = scheduledLocal.toUtc();
    final tzScheduled = tz.TZDateTime.from(scheduledUtc, tz.UTC);

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'ÉMU Compagnon',
      "C'est l'heure de votre lecture — un verset, un chapitre, un instant avec la Parole.",
      tzScheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Rappel quotidien',
          channelDescription: 'Rappel journalier de lecture biblique',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDaily() async {
    await init();
    await _plugin.cancel(_dailyReminderId);
  }
}
