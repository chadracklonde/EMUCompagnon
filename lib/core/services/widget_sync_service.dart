import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/bible/repository/bible_repository.dart';
import '../../features/church_texts/data/church_texts_data.dart';
import '../../features/church_texts/models/church_text.dart';
import '../../features/church_texts/services/church_text_prefs.dart';
import '../../features/daily_quiz/services/daily_quiz_service.dart';
import '../../features/dictionary/repository/dictionary_repository.dart';
import '../../features/favorites/repository/bookmark_repository.dart';
import '../../features/hymn_lists/services/hymn_list_service.dart';
import '../../features/hymns/repository/hymns_repository.dart';
import '../../features/hymns/utils/hymn_stanza_parser.dart';
import '../../features/liturgy/models/liturgical_period.dart';
import '../../features/liturgy/services/liturgical_calendar_service.dart';
import '../../features/memorization/repository/memory_card_repository.dart';
import '../../features/reading_plan/services/reading_plan_service.dart';
import '../../features/worship/services/worship_service.dart';
import '../database/db_helper.dart';
import '../models/bookmark.dart';
import '../models/hymn.dart';
import '../models/verse.dart';
import '../services/reading_history_service.dart';
import '../services/streak_service.dart';
import '../services/weekly_challenge_service.dart';
import 'widget_data.dart';

/// Feeds the widgets of the Android home screen.
///
/// A widget cannot ask the database, so the app writes what each one shows
/// into its preferences, then asks the native side to redraw them. Daily
/// widgets get the next [days] days at once, so they stay right when the
/// app is not opened. The native side is in native/android/.
class WidgetSyncService {
  /// Preferences key of the "Verset du jour" widget (stored as "flutter.<key>").
  static const prefsKey = 'widget.verses';

  /// Preferences key of every other widget: `{widgetKey: entry}`.
  static const dataKey = 'widget.data';

  /// How many days ahead are written.
  static const days = 14;

  static const _channel = MethodChannel('emu_compagnon/widgets');

  static String dateKey(DateTime d) => WidgetData.dayKey(d);

  /// The JSON the verse widget reads: `{"2026-11-11": {"t": text, "r": reference}}`.
  static String encode(Map<DateTime, Verse> verses) => jsonEncode({
        for (final e in verses.entries)
          dateKey(e.key): {'t': e.value.text.trim(), 'r': e.value.reference},
      });

  static bool _syncing = false;

  static Future<void> sync() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_syncing) return;
    _syncing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();

      final verses = <DateTime, Verse>{};
      try {
        final repo = BibleRepository();
        for (var i = 0; i < days; i++) {
          final day = DateTime(today.year, today.month, today.day + i);
          final verse = await repo.getVerseOfTheDay(date: day);
          if (verse != null) verses[day] = verse;
        }
      } catch (_) {}
      if (verses.isNotEmpty) await prefs.setString(prefsKey, encode(verses));

      final data = await _collect(today);
      await prefs.setString(dataKey, jsonEncode(data));
      try {
        await _channel.invokeMethod<void>('refresh');
      } catch (_) {
        // Older builds without the channel: widgets update on their own schedule.
      }
    } catch (_) {
      // Widgets are a convenience: they keep showing what they last knew.
    } finally {
      _syncing = false;
    }
  }

  /// Runs one widget's collector; a failure only leaves that widget out.
  static Future<void> _put(
    Map<String, dynamic> out,
    String key,
    Future<Map<String, dynamic>?> Function() collect,
  ) async {
    try {
      final entry = await collect();
      if (entry != null) out[key] = entry;
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> _collect(DateTime today) async {
    final out = <String, dynamic>{};

    await _put(out, 'reading_plan', () async {
      final plan = await ReadingPlanService.getPlan();
      final day = plan.nextDay;
      final progress = (plan.progress * 100).round();
      final footer = '${plan.readChapters} sur ${plan.totalChapters} chapitres lus';
      if (day == null) {
        return {'t': 'Plan terminé', 'b': 'Bravo, vous avez lu toute la Bible !', 'p': 100, 'f': footer};
      }
      return {
        't': day.label,
        'b': '${WidgetData.plural(day.chapters.length, 'chapitre', 'chapitres')} · ${day.verses} versets',
        'p': progress,
        'f': footer,
      };
    });

    LiturgicalPeriodInstance? seasonOn(DateTime d) {
      try {
        return LiturgicalCalendarService.currentSeason(d).$1;
      } catch (_) {
        return null;
      }
    }

    await _put(out, 'season', () async => WidgetData.daily(today, days, (day) {
          final s = seasonOn(day);
          if (s == null) return {};
          return {
            't': s.period.name,
            'b': s.period.summary,
            'f': 'Couleur : ${s.period.colorName}',
            'c': s.period.colorHex,
          };
        }));

    await _put(out, 'color', () async => WidgetData.daily(today, days, (day) {
          final s = seasonOn(day);
          if (s == null) return {};
          return {'t': s.period.colorName, 'b': s.period.name, 'c': s.period.colorHex};
        }));

    await _put(out, 'next_sunday', () async => WidgetData.daily(today, days, (day) {
          final sunday = WorshipService.serviceDay(day);
          final s = seasonOn(sunday);
          if (s == null) return {'t': WidgetData.longDate(sunday)};
          return {
            't': WidgetData.longDate(sunday),
            'b': s.period.name,
            'f': 'Couleur : ${s.period.colorName}',
            'c': s.period.colorHex,
          };
        }));

    // Upcoming seasons and holy days, from today on.
    List<LiturgicalPeriodInstance> upcoming(DateTime day) {
      final start = LiturgicalCalendarService.churchYearStartFor(day);
      final all = [
        ...LiturgicalCalendarService.periodsForChurchYear(start),
        ...LiturgicalCalendarService.periodsForChurchYear(start + 1),
      ].where((p) => !WidgetData.dayOnly(p.start).isBefore(WidgetData.dayOnly(day))).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      return all;
    }

    await _put(out, 'countdown', () async => WidgetData.daily(today, days, (day) {
          final next = upcoming(day);
          if (next.isEmpty) return {};
          final p = next.first;
          final left = WidgetData.dayOnly(p.start).difference(WidgetData.dayOnly(day)).inDays;
          return {
            't': WidgetData.countdownTitle(left),
            'b': left <= 0 ? p.period.name : 'avant ${p.period.name}',
            'f': WidgetData.longDate(p.start),
            'c': p.period.colorHex,
          };
        }));

    await _put(out, 'calendar', () async => WidgetData.daily(today, days, (day) => {
          'items': [
            for (final p in upcoming(day).take(5)) '${WidgetData.shortDate(p.start)} · ${p.period.name}',
          ],
        }));

    await _put(out, 'worship_hymns', () async {
      final lists = await HymnListService.getAll();
      if (lists.isEmpty) return null;
      final chosenId = await WorshipService.chosenListId();
      final list = lists.firstWhere((l) => l.id == chosenId, orElse: () => lists.first);
      final repo = HymnsRepository();
      final items = <String>[];
      for (final number in list.numbers.take(5)) {
        final hymn = await repo.getByNumber(number);
        if (hymn != null) items.add('${hymn.number} · ${hymn.title}');
      }
      if (items.isEmpty) return null;
      final more = list.numbers.length - items.length;
      return {
        'l': 'CANTIQUES DU CULTE · ${list.name.toUpperCase()}',
        'items': items,
        'f': more > 0 ? '+ $more autre${more > 1 ? 's' : ''}' : '',
      };
    });

    await _put(out, 'streak', () async {
      final info = await StreakService.getCurrent();
      return {
        't': WidgetData.plural(info.current, 'jour', 'jours'),
        'b': "d'affilée",
        'f': 'Record : ${WidgetData.plural(info.longest, 'jour', 'jours')}',
      };
    });

    await _put(out, 'week', () async {
      final info = await StreakService.getCurrent();
      final last = await StreakService.getLastActive();
      final dots = WidgetData.weekDots(today: today, lastActive: last, streak: info.current);
      final n = dots.fold<int>(0, (a, b) => a + b);
      return {
        't': '$n jour${n > 1 ? 's' : ''} sur 7',
        'd': dots,
        'f': 'Série en cours : ${WidgetData.plural(info.current, 'jour', 'jours')}',
      };
    });

    await _put(out, 'memorize', () async {
      final repo = MemoryCardRepository();
      final due = await repo.getDueToday();
      if (due.isEmpty) {
        final all = await repo.getAll();
        if (all.isEmpty) return null;
        return {
          't': all.first.referenceLabel,
          'b': WidgetData.truncate(all.first.verseText, 180),
          'f': 'Rien à réviser aujourd\'hui',
        };
      }
      return {
        't': due.first.referenceLabel,
        'b': WidgetData.truncate(due.first.verseText, 180),
        'f': '${due.length} à réviser aujourd\'hui',
      };
    });

    await _put(out, 'pinned_text', () async {
      final pinned = await ChurchTextPrefs.pinned();
      final text = (pinned.isEmpty ? null : ChurchTextsData.byId(pinned.first)) ?? ChurchTextsData.lordsPrayer;
      final body = text.blocks
          .where((b) => b.kind != TextBlockKind.heading && b.kind != TextBlockKind.note)
          .map((b) => b.text)
          .join(' ');
      return {'t': text.title, 'b': WidgetData.truncate(body, 240), 'r': 'text:${text.id}'};
    });

    await _put(out, 'hymn_of_day', () async {
      final hymns = await HymnsRepository().getAll();
      if (hymns.isEmpty) return null;
      return WidgetData.daily(today, days, (day) => _hymnEntry(WidgetData.pickByDay(hymns, day)));
    });

    await _put(out, 'resume_bible', () async {
      final last = await ReadingHistoryService.getLastBibleRead();
      if (last == null) return null;
      return {
        't': '${last.book} ${last.chapter}',
        'b': 'Reprendre la lecture',
        'r': 'chapter|${last.book}|${last.chapter}',
      };
    });

    await _put(out, 'resume_hymn', () async {
      final last = await ReadingHistoryService.getLastHymnRead();
      if (last == null) return null;
      return {'t': 'N° ${last.number}', 'b': last.title, 'r': 'hymn:${last.number}'};
    });

    await _put(out, 'favorites', () async {
      final repo = BookmarkRepository();
      final bookmarks = [
        ...await repo.listByType(BookmarkType.verse),
        ...await repo.listByType(BookmarkType.hymn),
      ];
      if (bookmarks.isEmpty) return null;
      final db = await DbHelper.database;
      final entries = <String, Map<String, dynamic>>{};
      for (var i = 0; i < days; i++) {
        final day = DateTime(today.year, today.month, today.day + i);
        final b = WidgetData.pickByDay(bookmarks, day);
        final entry = b.type == BookmarkType.verse
            ? await _favoriteVerse(db, b.refId)
            : await _favoriteHymn(db, b.refId);
        if (entry != null) entries[WidgetData.dayKey(day)] = entry;
      }
      return entries.isEmpty ? null : {'days': entries};
    });

    await _put(out, 'challenge', () async {
      final done = await WeeklyChallengeService.isCurrentCompleted();
      return {
        't': WeeklyChallengeService.getCurrentChallenge(),
        'f': done ? 'Accompli ✓' : 'À accomplir cette semaine',
      };
    });

    await _put(out, 'quiz', () async {
      final result = await DailyQuizService.getTodayResult();
      if (result == null) return {'t': '${DailyQuizService.questionsPerDay} questions'};
      return {'t': 'Score : ${result.score}/${result.total}', 'b': 'Bravo ! Revenez demain.'};
    });

    await _put(out, 'word', () async {
      final entries = await DictionaryRepository().getAll();
      if (entries.isEmpty) return null;
      return WidgetData.daily(today, days, (day) {
        final e = WidgetData.pickByDay(entries, day);
        return {'t': e.term, 'b': WidgetData.truncate(e.definition, 200), 'r': 'dictionary:${e.id}'};
      });
    });

    return out;
  }

  static Map<String, dynamic> _hymnEntry(Hymn hymn) {
    final stanzas = HymnStanzaParser.parse(hymn.lyrics);
    HymnStanza? chosen;
    for (final s in stanzas) {
      if (s.isRefrain) {
        chosen = s;
        break;
      }
    }
    chosen ??= stanzas.isEmpty ? null : stanzas.first;
    return {
      't': 'N° ${hymn.number} — ${hymn.title}',
      'b': chosen == null ? '' : WidgetData.truncate(chosen.body, 200),
      'r': 'hymn:${hymn.number}',
    };
  }

  static Future<Map<String, dynamic>?> _favoriteVerse(dynamic db, int id) async {
    final rows = await db.query('bible_verses', where: 'id = ?', whereArgs: [id], limit: 1) as List;
    if (rows.isEmpty) return null;
    final v = Verse.fromMap(Map<String, dynamic>.from(rows.first as Map));
    return {
      't': v.reference,
      'b': WidgetData.truncate(v.text, 200),
      'r': 'chapter|${v.book}|${v.chapter}',
    };
  }

  static Future<Map<String, dynamic>?> _favoriteHymn(dynamic db, int id) async {
    final rows = await db.query('hymns', where: 'id = ?', whereArgs: [id], limit: 1) as List;
    if (rows.isEmpty) return null;
    return _hymnEntry(Hymn.fromMap(Map<String, dynamic>.from(rows.first as Map)));
  }
}
