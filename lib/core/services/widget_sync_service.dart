import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verse.dart';
import '../../features/bible/repository/bible_repository.dart';

/// Feeds the "Verset du jour" widget of the Android home screen.
///
/// The widget cannot ask the database, so each time the app starts it
/// writes the verses of the coming days; the widget shows the one of the
/// current day, even when the app is not opened for a while. The native
/// side is in native/android/.
class WidgetSyncService {
  /// Preferences key read by the Kotlin widget (stored as "flutter.<key>").
  static const prefsKey = 'widget.verses';

  /// How many days ahead are written.
  static const days = 14;

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The JSON the widget reads: `{"2026-11-11": {"t": text, "r": reference}}`.
  static String encode(Map<DateTime, Verse> verses) => jsonEncode({
        for (final e in verses.entries)
          dateKey(e.key): {'t': e.value.text.trim(), 'r': e.value.reference},
      });

  static Future<void> sync() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final repo = BibleRepository();
      final today = DateTime.now();
      final verses = <DateTime, Verse>{};
      for (var i = 0; i < days; i++) {
        final day = DateTime(today.year, today.month, today.day + i);
        final verse = await repo.getVerseOfTheDay(date: day);
        if (verse != null) verses[day] = verse;
      }
      if (verses.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, encode(verses));
    } catch (_) {
      // The widget is a convenience: without fresh data it keeps showing
      // the last verse it knows.
    }
  }
}
