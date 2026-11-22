import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/help/data/help_content.dart';
import 'package:emu_compagnon/features/help/screens/help_article_screen.dart';
import 'package:emu_compagnon/features/help/screens/help_screen.dart';
import 'package:emu_compagnon/features/more/screens/more_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettings> _settings(String locale) async {
  SharedPreferences.setMockInitialValues({'settings.locale': locale});
  final s = AppSettings();
  await s.load();
  return s;
}

Future<void> _pump(WidgetTester tester, AppSettings s, Widget home) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
      value: s, child: MaterialApp(home: home)));
  await tester.pump();
}

void main() {
  group('contenu', () {
    test('chaque texte existe en français et en swahili, sans doublon d\'identifiant', () {
      final ids = <String>{};
      for (final a in HelpContent.articles) {
        expect(ids.add(a.id), isTrue, reason: 'doublon ${a.id}');
        final texts = [a.title, a.subtitle, a.intro, ...a.steps.map((s) => s.text)];
        for (final t in texts) {
          expect(t.fr.trim(), isNotEmpty);
          expect(t.sw.trim(), isNotEmpty);
          expect(t.sw, isNot(t.fr), reason: 'swahili identique au français : ${t.fr}');
        }
        expect(a.steps.length, inInclusiveRange(2, 6));
      }
    });

    test('la recherche ignore les accents, les majuscules et exige tous les mots', () {
      expect(HelpContent.search('etude', 'fr').map((a) => a.id), contains('annotated'));
      expect(HelpContent.search('BIBLE ANNOTÉE', 'fr').first.id, 'annotated');
      expect(HelpContent.search('sauvegarde export', 'fr').map((a) => a.id), ['backup']);
      expect(HelpContent.search('zzzz', 'fr'), isEmpty);
      expect(HelpContent.search('  ', 'fr').length, HelpContent.articles.length);
      expect(HelpContent.search('funzo', 'sw').map((a) => a.id), contains('annotated'));
    });
  });

  group('écrans', () {
    testWidgets('l\'aide liste les sujets en français', (tester) async {
      await _pump(tester, await _settings('fr'), const HelpScreen());
      expect(find.text('Aide'), findsOneWidget);
      expect(find.text('Bien commencer'), findsOneWidget);
      expect(find.text('La Bible annotée'), findsOneWidget);
      expect(find.text('Cantiques et listes'), findsOneWidget);
    });

    testWidgets('l\'aide est en swahili quand l\'application l\'est', (tester) async {
      await _pump(tester, await _settings('sw'), const HelpScreen());
      expect(find.text('Msaada'), findsOneWidget);
      expect(find.text('Kuanza vizuri'), findsOneWidget);
      expect(find.text('Biblia yenye maelezo'), findsOneWidget);
    });

    testWidgets('la recherche filtre la liste, puis on l\'efface', (tester) async {
      await _pump(tester, await _settings('fr'), const HelpScreen());
      await tester.enterText(find.byType(TextField), 'sauvegarde');
      await tester.pump();
      expect(find.text('Sauvegarder mes données'), findsOneWidget);
      expect(find.text('La Bible annotée'), findsNothing);
      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();
      expect(find.textContaining('Aucun sujet'), findsOneWidget);
      await tester.tap(find.byTooltip('Effacer la recherche'));
      await tester.pump();
      expect(find.text('La Bible annotée'), findsOneWidget);
    });

    testWidgets('toucher un sujet ouvre ses étapes numérotées', (tester) async {
      await _pump(tester, await _settings('fr'), const HelpScreen());
      await tester.tap(find.text('La Bible annotée'));
      await tester.pumpAndSettle();
      final a = HelpContent.byId('annotated')!;
      expect(find.text(a.intro.fr), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Ouvrir la Bible'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Ouvrir la Bible'), findsOneWidget);
    });

    testWidgets('l\'article n\'a pas de bouton quand il n\'ouvre aucun écran', (tester) async {
      final a = HelpArticle(
        id: 'x',
        icon: Icons.help,
        title: const L('Titre', 'Kichwa'),
        subtitle: const L('Sous-titre', 'Kichwa kidogo'),
        intro: const L('Intro', 'Utangulizi'),
        steps: const [HelpStep(L('Une', 'Moja'))],
      );
      await _pump(tester, await _settings('fr'), HelpArticleScreen(article: a));
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Une'), findsOneWidget);
    });

    testWidgets('l\'onglet Plus a une ligne Aide qui ouvre l\'aide', (tester) async {
      await _pump(tester, await _settings('fr'), const MoreScreen());
      final row = find.text('Comment utiliser l\'application');
      await tester.scrollUntilVisible(row, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);
    });
  });
}
