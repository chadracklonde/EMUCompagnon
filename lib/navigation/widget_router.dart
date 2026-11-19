import 'package:flutter/material.dart';
import '../features/bible/screens/chapter_screen.dart';
import '../features/church_texts/data/church_texts_data.dart';
import '../features/church_texts/screens/church_text_screen.dart';
import '../features/church_texts/screens/church_texts_screen.dart';
import '../features/daily_quiz/screens/daily_quiz_screen.dart';
import '../features/dictionary/repository/dictionary_repository.dart';
import '../features/dictionary/screens/dictionary_detail_screen.dart';
import '../features/evening_examen/screens/evening_examen_screen.dart';
import '../features/hymns/repository/hymns_repository.dart';
import '../features/hymns/screens/hymn_pager_screen.dart';
import '../features/journal/screens/journal_screen.dart';
import '../features/liturgy/screens/liturgical_calendar_screen.dart';
import '../features/memorization/screens/memorization_screen.dart';
import '../features/reading_plan/screens/reading_plan_screen.dart';
import '../features/search/screens/global_search_screen.dart';
import '../features/weekly_challenge/screens/weekly_challenge_screen.dart';
import '../features/worship/screens/worship_screen.dart';

/// Where a tap on a widget or on an app-icon shortcut leads. A route is a
/// short word ("worship"), a word with an argument ("hymn:12") or, for a
/// Bible chapter, "chapter|Jean|4" (book names can hold spaces and digits).
class WidgetRouter {
  /// Tabs of the app shell a route can select instead of opening a screen.
  static const tabRoutes = {'home': 0, 'bible': 1, 'hymns': 2, 'liturgy': 3};

  static String? _lastRoute;
  static DateTime? _lastAt;

  /// The same route arriving twice in a row (cold start: the plugin reports
  /// it both ways) is handled once.
  static bool isDuplicate(String route, DateTime now) {
    final repeated = route == _lastRoute &&
        _lastAt != null &&
        now.difference(_lastAt!) < const Duration(seconds: 2);
    _lastRoute = route;
    _lastAt = now;
    return repeated;
  }

  /// The screen of a route that needs no lookup, or null.
  static Widget? screenFor(String route) {
    switch (route) {
      case 'search':
        return const GlobalSearchScreen();
      case 'worship':
        return const WorshipScreen();
      case 'reading_plan':
        return const ReadingPlanScreen();
      case 'calendar':
        return const LiturgicalCalendarScreen();
      case 'memorization':
        return const MemorizationScreen();
      case 'quiz':
        return const DailyQuizScreen();
      case 'challenge':
        return const WeeklyChallengeScreen();
      case 'examen':
        return const EveningExamenScreen();
      case 'journal':
        return const JournalScreen();
      case 'texts':
        return const ChurchTextsScreen();
      case 'dictionary':
        return null;
    }
    if (route.startsWith('text:')) {
      final text = ChurchTextsData.byId(route.substring(5));
      if (text != null) return ChurchTextScreen(text: text);
    }
    if (route.startsWith('chapter|')) {
      final parts = route.split('|');
      final chapter = parts.length == 3 ? int.tryParse(parts[2]) : null;
      if (chapter != null) return ChapterScreen(book: parts[1], chapter: chapter);
    }
    return null;
  }

  /// Opens [route]. [selectTab] is called for the routes that are tabs.
  static Future<void> open(
    BuildContext context,
    String route, {
    required void Function(int index) selectTab,
  }) async {
    if (isDuplicate(route, DateTime.now())) return;
    final navigator = Navigator.of(context);
    final tab = tabRoutes[route];
    if (tab != null) {
      navigator.popUntil((r) => r.isFirst);
      selectTab(tab);
      return;
    }
    Widget? screen = screenFor(route);
    if (screen == null && route.startsWith('hymn:')) {
      final hymn = await HymnsRepository().getByNumber(route.substring(5));
      if (hymn != null) screen = HymnPagerScreen(hymn: hymn);
    } else if (screen == null && route.startsWith('dictionary:')) {
      final id = int.tryParse(route.substring(11));
      if (id != null) {
        final entries = await DictionaryRepository().getByIds([id]);
        if (entries.isNotEmpty) screen = DictionaryDetailScreen(entry: entries.first);
      }
    }
    if (screen == null || !context.mounted) return;
    navigator.push(MaterialPageRoute(builder: (_) => screen!));
  }
}
