import 'dart:convert';
import 'dart:io';

import 'package:emu_compagnon/core/services/widget_catalog.dart';
import 'package:emu_compagnon/features/bible/data/comfort_verses.dart';
import 'package:emu_compagnon/core/services/widget_data.dart';
import 'package:emu_compagnon/features/bible/screens/chapter_screen.dart';
import 'package:emu_compagnon/features/church_texts/screens/church_text_screen.dart';
import 'package:emu_compagnon/features/worship/screens/worship_screen.dart';
import 'package:emu_compagnon/navigation/widget_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('widget text', () {
    test('truncates at a word end', () {
      expect(WidgetData.truncate('Car Dieu a tant aimé le monde', 100), 'Car Dieu a tant aimé le monde');
      expect(WidgetData.truncate('Car Dieu a tant aimé le monde, qu\'il a donné', 20), 'Car Dieu a tant…');
    });

    test('collapses line breaks', () {
      expect(WidgetData.truncate('Un\n\nDeux   trois', 50), 'Un Deux trois');
    });

    test('dates in French', () {
      expect(WidgetData.longDate(DateTime(2026, 11, 15)), 'dimanche 15 novembre');
      expect(WidgetData.shortDate(DateTime(2026, 12, 25)), '25 déc.');
    });

    test('countdown titles', () {
      expect(WidgetData.countdownTitle(0), "Aujourd'hui");
      expect(WidgetData.countdownTitle(1), 'Demain');
      expect(WidgetData.countdownTitle(42), '42 jours');
    });

    test('plural', () {
      expect(WidgetData.plural(1, 'jour', 'jours'), '1 jour');
      expect(WidgetData.plural(0, 'jour', 'jours'), '0 jour');
      expect(WidgetData.plural(5, 'jour', 'jours'), '5 jours');
    });
  });

  group('week dots', () {
    // Wednesday 11 November 2026.
    final today = DateTime(2026, 11, 11);

    test('no streak, no dot', () {
      expect(WidgetData.weekDots(today: today, lastActive: null, streak: 0), List.filled(7, 0));
    });

    test('a streak ending today marks its days of this week', () {
      expect(
        WidgetData.weekDots(today: today, lastActive: today, streak: 2),
        [0, 1, 1, 0, 0, 0, 0],
      );
    });

    test('a long streak fills the days from Monday', () {
      expect(
        WidgetData.weekDots(today: today, lastActive: today, streak: 30),
        [1, 1, 1, 0, 0, 0, 0],
      );
    });

    test('a streak that stopped yesterday still shows its days', () {
      expect(
        WidgetData.weekDots(today: today, lastActive: DateTime(2026, 11, 10), streak: 2),
        [1, 1, 0, 0, 0, 0, 0],
      );
    });
  });

  group('daily entries', () {
    test('one entry per day, keyed by date, from today', () {
      final data = WidgetData.daily(DateTime(2026, 12, 30), 4, (d) => {'t': '${d.day}'});
      final days = data['days'] as Map<String, dynamic>;
      expect(days.keys, ['2026-12-30', '2026-12-31', '2027-01-01', '2027-01-02']);
      expect(days['2027-01-01'], {'t': '1'});
    });

    test('a different item each day, in turn', () {
      final items = ['a', 'b', 'c'];
      final picked = [
        for (var i = 0; i < 4; i++) WidgetData.pickByDay(items, DateTime(2026, 3, 1 + i)),
      ];
      expect(picked.toSet().length, 3);
      expect(picked[0], picked[3]);
    });
  });

  group('widget routes', () {
    test('plain routes open their screen', () {
      expect(WidgetRouter.screenFor('worship'), isA<WorshipScreen>());
    });

    test('a text opens by id, an unknown one does nothing', () {
      expect(WidgetRouter.screenFor('text:notre_pere'), isA<ChurchTextScreen>());
      expect(WidgetRouter.screenFor('text:inconnu'), isNull);
    });

    test('a chapter route keeps book names with spaces', () {
      final screen = WidgetRouter.screenFor('chapter|1 Corinthiens|13') as ChapterScreen;
      expect(screen.book, '1 Corinthiens');
      expect(screen.chapter, 13);
      expect(WidgetRouter.screenFor('chapter|Jean|x'), isNull);
    });

    test('tabs are selected, not opened as screens', () {
      expect(WidgetRouter.tabRoutes['hymns'], 2);
      expect(WidgetRouter.screenFor('hymns'), isNull);
    });

    test('the same route twice in a row is handled once', () {
      final t = DateTime(2026, 11, 11, 9);
      expect(WidgetRouter.isDuplicate('quiz', t), isFalse);
      expect(WidgetRouter.isDuplicate('quiz', t.add(const Duration(milliseconds: 500))), isTrue);
      expect(WidgetRouter.isDuplicate('quiz', t.add(const Duration(seconds: 10))), isFalse);
    });
  });

  group('verse of the day', () {
    test('a different verse every day, none repeated within a cycle', () {
      final n = ComfortVerses.all.length;
      // A cycle is n days counted from 1 January 2024.
      for (final cycle in [0, 7, 11]) {
        final seen = <int>{};
        for (var i = 0; i < n; i++) {
          seen.add(ComfortVerses.indexFor(DateTime(2024, 1, 1 + cycle * n + i)));
        }
        expect(seen.length, n, reason: 'cycle $cycle');
      }
    });

    test('never the same verse two days in a row, across cycles too', () {
      final n = ComfortVerses.all.length;
      var previous = ComfortVerses.indexFor(DateTime(2026, 1, 1));
      for (var i = 1; i < n * 4; i++) {
        final current = ComfortVerses.indexFor(DateTime(2026, 1, 1 + i));
        expect(current, isNot(previous), reason: 'day $i');
        previous = current;
      }
    });

    test('the order is not the order of the list', () {
      final picks = [for (var i = 0; i < 10; i++) ComfortVerses.indexFor(DateTime(2026, 5, 1 + i))];
      final consecutive = [for (var i = 1; i < picks.length; i++) picks[i] - picks[i - 1] == 1].where((b) => b).length;
      expect(consecutive, lessThan(4));
    });

    test('the same day always gives the same verse', () {
      expect(ComfortVerses.indexFor(DateTime(2026, 11, 12, 6)), ComfortVerses.indexFor(DateTime(2026, 11, 12, 23)));
    });

    test('the list has no duplicates', () {
      final keys = {for (final v in ComfortVerses.all) '${v.book} ${v.chapter}.${v.verse}'};
      expect(keys.length, ComfortVerses.all.length);
    });

    test('Psalm numbering marks, inscriptions and "Pause" are removed', () {
      expect(ComfortVerses.cleanText('Psaumes', "(34 :6) Quand on tourne vers lui les regards, on est rayonnant de joie,"),
          'Quand on tourne vers lui les regards, on est rayonnant de joie,');
      expect(ComfortVerses.cleanText('Psaumes', "Cantique de David. L'Éternel est mon berger : je ne manquerai de rien."),
          "L'Éternel est mon berger : je ne manquerai de rien.");
      expect(ComfortVerses.cleanText('Psaumes', "De David. L'Éternel est ma lumière et mon salut."),
          "L'Éternel est ma lumière et mon salut.");
      expect(ComfortVerses.cleanText('Psaumes', "(46 :12) L'Éternel des armées est avec nous. -Pause."),
          "L'Éternel des armées est avec nous.");
    });

    test('other books are left alone, even when they start like an inscription', () {
      const text = 'Cantique des cantiques de Salomon. Il est beau.';
      expect(ComfortVerses.cleanText('Cantique', text), text);
    });
  });

  group('widget layouts', () {
    // The only views a RemoteViews (a widget) may inflate; anything else,
    // a plain <View> included, makes Android show "Impossible de charger
    // le widget".
    const allowed = {
      'FrameLayout', 'LinearLayout', 'RelativeLayout', 'GridLayout', 'AbsoluteLayout',
      'AnalogClock', 'Button', 'Chronometer', 'ImageButton', 'ImageView', 'ProgressBar',
      'TextClock', 'TextView', 'ViewFlipper', 'ListView', 'GridView', 'StackView',
      'AdapterViewFlipper', 'ViewStub',
    };

    test('only use views a widget may inflate', () {
      final layouts = Directory('native/android/res/layout').listSync().whereType<File>();
      expect(layouts, isNotEmpty);
      for (final file in layouts) {
        final tags = RegExp(r'<([A-Za-z][A-Za-z0-9.]*)').allMatches(file.readAsStringSync());
        for (final m in tags) {
          expect(allowed, contains(m.group(1)), reason: '${file.path}: <${m.group(1)}>');
        }
      }
    });
  });

  group('widget declarations', () {
    final widgets = (jsonDecode(File('native/android/widgets.json').readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

    test('keys and classes are unique', () {
      expect({for (final w in widgets) w['key']}.length, widgets.length);
      expect({for (final w in widgets) w['cls']}.length, widgets.length);
    });

    test('every widget has a known layout and size', () {
      for (final w in widgets) {
        expect(['card', 'week', 'list', 'shortcuts'], contains(w['kind']), reason: w['key']);
        expect(['small', 'medium', 'tall', 'wide'], contains(w['size']), reason: w['key']);
      }
    });

    test('every default tap leads somewhere the app understands', () {
      const plain = {
        'home', 'search', 'worship', 'reading_plan', 'calendar', 'memorization', 'quiz',
        'challenge', 'examen', 'journal', 'texts', 'bible', 'hymns', 'liturgy',
      };
      for (final w in widgets) {
        final route = (w['defaults'] as Map)['r'] as String;
        expect(plain, contains(route), reason: w['key']);
      }
    });

    test('the catalog on the Widgets screen matches the declarations', () {
      final byKey = {for (final w in WidgetCatalog.all) w.key: w};
      expect(byKey.length, widgets.length + 1, reason: 'declared widgets + the verse widget');
      for (final w in widgets) {
        final info = byKey[w['key']];
        expect(info, isNotNull, reason: w['key']);
        expect(info!.label, w['label'], reason: w['key']);
        expect(info.description, w['desc'], reason: w['key']);
      }
      for (final w in WidgetCatalog.all) {
        expect(WidgetCatalog.families, contains(w.family), reason: w.key);
      }
    });

    test('the app writes data for each widget key (or it is static)', () {
      final source = File('lib/core/services/widget_sync_service.dart').readAsStringSync();
      const static = {'shortcuts', 'examen', 'journal', 'search'};
      for (final w in widgets) {
        final key = w['key'] as String;
        if (static.contains(key)) continue;
        expect(source, contains("'$key'"), reason: key);
      }
    });
  });
}
