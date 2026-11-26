import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/bible_quiz/models/bible_quiz_question.dart';
import 'package:emu_compagnon/features/bible_quiz/screens/bible_quiz_screen.dart';
import 'package:emu_compagnon/features/bible_quiz/services/bible_quiz_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bundle that serves one string for the quiz asset.
class _FakeBundle extends CachingAssetBundle {
  final String json;
  _FakeBundle(this.json);
  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(json));
    return ByteData.sublistView(bytes);
  }
}

String _fixture() => jsonEncode({
      'v': 1,
      'q': [
        for (var i = 1; i <= 24; i++)
          {
            'id': 'T$i',
            't': 'Question $i ?',
            'o': ['Faux 1', 'Bonne $i', 'Faux 2', 'Faux 3'],
            'a': 1,
            'c': 'Événements',
            'n': (i % 3) + 1,
            'b': i.isEven ? 'AT' : 'NT',
            if (i == 1) 'r': ['Genèse 1.1'],
          },
      ],
    });

void main() {
  group('banque embarquée', () {
    late List<BibleQuizQuestion> all;
    setUpAll(() {
      all = BibleQuizService.parse(File('assets/quiz/quiz_fr.json').readAsStringSync());
    });

    test('contient plus de 3 000 questions valides, identifiants uniques', () {
      expect(all.length, greaterThan(3000));
      expect(all.map((q) => q.id).toSet().length, all.length);
      for (final q in all) {
        expect(q.options.length, inInclusiveRange(2, 5), reason: q.id);
        expect(q.correctIndex, lessThan(q.options.length), reason: q.id);
        expect(q.options.map((o) => o.trim().toLowerCase()).toSet().length, q.options.length,
            reason: 'options en double : ${q.id}');
        expect(q.text.trim(), isNotEmpty);
        expect(q.level, inInclusiveRange(1, 3));
      }
    });

    test('la bonne réponse est répartie sur toutes les positions', () {
      final counts = List.filled(4, 0);
      for (final q in all) {
        if (q.correctIndex < 4) counts[q.correctIndex]++;
      }
      for (final c in counts) {
        expect(c, greaterThan(all.length * 0.15));
      }
    });

    test('aucun reste de l’anglais ou d’options absurdes connues', () {
      final bad = RegExp(r'\b(pizza|hamburger|Vikings?|Bar Mitzvah|band\b|emerolds)\b', caseSensitive: false);
      for (final q in all) {
        expect(bad.hasMatch('${q.text} ${q.options.join(' ')}'), isFalse, reason: q.id);
      }
    });
  });

  group('tirage', () {
    final all = BibleQuizService.parse(_fixture());

    test('dix questions par défaut, sans doublon', () {
      final s = BibleQuizService.pick(all, random: Random(1));
      expect(s.length, 10);
      expect(s.map((q) => q.id).toSet().length, 10);
    });

    test('filtre par testament et difficulté', () {
      final at = BibleQuizService.pick(all, testament: 'AT', random: Random(1));
      expect(at.every((q) => q.testament == 'AT'), isTrue);
      final hard = BibleQuizService.pick(all, level: 3, random: Random(1));
      expect(hard.every((q) => q.level == 3), isTrue);
    });

    test('évite les questions déjà vues tant qu’il en reste', () {
      final seen = {for (var i = 1; i <= 12; i++) 'T$i'};
      final s = BibleQuizService.pick(all, seen: seen, random: Random(2));
      expect(s.every((q) => !seen.contains(q.id)), isTrue);
    });

    test('réutilise le pool complet quand il n’y a plus assez de nouveautés', () {
      final seen = {for (var i = 1; i <= 22; i++) 'T$i'};
      final s = BibleQuizService.pick(all, seen: seen, random: Random(3));
      expect(s.length, 10);
    });

    test('un filtre sans résultat renvoie une liste vide', () {
      final one = BibleQuizService.parse(jsonEncode({
        'q': [
          {'id': 'X', 't': 'Q ?', 'o': ['a', 'b'], 'a': 0, 'n': 1, 'b': 'AT'}
        ]
      }));
      expect(BibleQuizService.pick(one, testament: 'NT'), isEmpty);
    });
  });

  group('mémoire locale', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('retient les questions vues et borne la liste', () async {
      await BibleQuizService.markSeen(['A', 'B']);
      await BibleQuizService.markSeen(['A', 'C']);
      expect(await BibleQuizService.loadSeen(), {'A', 'B', 'C'});
      await BibleQuizService.markSeen([for (var i = 0; i < 700; i++) 'Z$i']);
      expect((await BibleQuizService.loadSeen()).length, 600);
    });

    test('garde le meilleur score', () async {
      await BibleQuizService.recordResult(6, 10);
      final s = await BibleQuizService.recordResult(4, 10);
      expect(s.gamesPlayed, 2);
      expect(s.bestScorePercent, 60);
    });
  });

  testWidgets('parcours complet : réglages, dix questions, score, référence', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.load();
    await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: MaterialApp(home: BibleQuizScreen(bundle: _FakeBundle(_fixture()))),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Quiz biblique'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 10'), findsOneWidget);

    for (var i = 0; i < 10; i++) {
      // la bonne réponse est toujours « Bonne n » dans la fixture
      await tester.tap(find.textContaining('Bonne'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(i == 9 ? 'Terminer' : 'Suivant'));
      await tester.pumpAndSettle();
    }
    expect(find.text('10 / 10'), findsOneWidget);
    expect(find.text('Quiz terminé'), findsOneWidget);
    expect(find.text('Meilleur score : 100 %'), findsOneWidget);
    await tester.tap(find.text('Retour aux réglages'));
    await tester.pumpAndSettle();
    expect(find.text('Commencer'), findsOneWidget);

    await settings.setLocale('sw');
    await tester.pumpAndSettle();
    expect(find.text('Jaribio la Biblia'), findsOneWidget);
    expect(find.text('Anza'), findsOneWidget);
  });

  testWidgets('un filtre sans question affiche un message', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.load();
    final only = jsonEncode({
      'q': [
        {'id': 'X', 't': 'Q ?', 'o': ['a', 'b'], 'a': 0, 'n': 1, 'b': 'AT'}
      ]
    });
    await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: MaterialApp(home: BibleQuizScreen(bundle: _FakeBundle(only))),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouveau'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucune question pour ce choix'), findsOneWidget);
  });
}
