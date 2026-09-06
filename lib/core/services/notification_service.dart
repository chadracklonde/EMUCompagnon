import 'package:flutter/foundation.dart' show kIsWeb;
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

  /// Windows requires a fixed, app-specific ID and GUID at init time —
  /// unlike Android/iOS/macOS, these aren't optional there.
  static const _windowsAppUserModelId = 'com.emucompagnon.emu_compagnon';
  static const _windowsGuid = 'a2f6b8e1-2c3d-4e5f-9a1b-6c7d8e9f0a1b';

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    // Without explicit Windows settings, initialize() silently fails to
    // wire up the Windows implementation at all — every notification
    // call afterward becomes a no-op with no error, which is exactly the
    // kind of "nothing happens, nothing tells you why" bug this app has
    // run into elsewhere in this project.
    const windowsInit = WindowsInitializationSettings(
      appName: 'ÉMU Compagnon',
      appUserModelId: _windowsAppUserModelId,
      guid: _windowsGuid,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
        windows: windowsInit,
      ),
    );
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false; // Notifications aren't offered on web (see SettingsScreen).
    await init();

    // No dart:io Platform check needed (and none allowed — this file must
    // stay compilable for web): resolvePlatformSpecificImplementation
    // simply returns null on any platform without a matching
    // implementation (Windows/Linux included), so `granted` naturally
    // stays true there without any extra branching.
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final macosImpl =
        _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();

    bool granted = true;
    if (androidImpl != null) {
      granted = await androidImpl.requestNotificationsPermission() ?? true;
    }
    if (iosImpl != null) {
      granted = await iosImpl.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    }
    if (macosImpl != null) {
      granted = await macosImpl.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    }
    return granted;
  }

  static Future<void> scheduleDaily({required int hour, required int minute}) async {
    if (kIsWeb) return;
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
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      // Required by the flutter_local_notifications version resolved for
      // this build (older builds of the API still need this even though
      // newer releases dropped it — kept for compatibility).
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelDaily() async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancel(_dailyReminderId);
  }
}
