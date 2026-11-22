import 'dart:convert';
import 'dart:io';

import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/help/data/help_content.dart';
import 'package:emu_compagnon/features/help/data/help_shots.dart';
import 'package:emu_compagnon/features/help/screens/help_article_screen.dart';
import 'package:emu_compagnon/features/help/screens/help_button.dart';
import 'package:emu_compagnon/features/help/screens/help_shot_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, String locale, Widget home) async {
  SharedPreferences.setMockInitialValues({'settings.locale': locale});
  final s = AppSettings();
  await s.load();
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
      value: s, child: MaterialApp(home: home)));
  // Les ressources se lisent de façon asynchrone.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(HelpShots.resetForTests);

  group('captures livrées (assets/help)', () {
    final manifest =
        jsonDecode(File('assets/help/shots.json').readAsStringSync()) as Map<String, dynamic>;

    test('chaque capture du manifeste a son image, et ses zones sont dans l\'image', () {
      var count = 0;
      for (final lang in manifest.keys) {
        for (final e in (manifest[lang] as Map<String, dynamic>).entries) {
          final f = File('assets/help/$lang/${e.key}.webp');
          expect(f.existsSync(), isTrue, reason: f.path);
          expect(f.lengthSync(), greaterThan(5000));
          expect(f.lengthSync(), lessThan(400 * 1024));
          final rects = (e.value['rects'] as Map<String, dynamic>);
          expect(rects, isNotEmpty);
          for (final r in rects.values) {
            final v = (r as List).cast<num>();
            expect(v[0], inInclusiveRange(0, 1));
            expect(v[1], inInclusiveRange(0, 1));
            expect(v[0] + v[2], lessThanOrEqualTo(1.001));
            expect(v[1] + v[3], lessThanOrEqualTo(1.001));
            expect(v[2], greaterThan(0));
            expect(v[3], greaterThan(0));
          }
          count++;
        }
      }
      expect(count, 9);
    });

    test('chaque capture citée dans l\'aide existe en français, avec toutes ses zones', () {
      for (final a in HelpContent.articles) {
        for (final s in a.steps) {
          final shot = s.shot;
          if (shot == null) continue;
          final entry = (manifest['fr'] as Map<String, dynamic>)[shot.id];
          expect(entry, isNotNull, reason: 'capture ${shot.id} absente en français');
          final rects = (entry['rects'] as Map<String, dynamic>).keys.toSet();
          for (final h in shot.hotspots) {
            expect(rects, contains(h.key), reason: '${shot.id}/${h.key}');
            expect(h.title.sw, isNot(h.title.fr));
            expect(h.body.sw, isNot(h.body.fr));
          }
        }
      }
    });
  });

  group('affichage', () {
    testWidgets('une capture s\'affiche sous son étape, avec le conseil', (tester) async {
      await _pump(tester, 'fr', HelpArticleScreen(article: HelpContent.byId('start')!));
      expect(find.byType(HelpShotView), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('Touchez un élément entouré'), findsOneWidget);
    });

    testWidgets('toucher une zone affiche sa bulle, la retoucher la ferme', (tester) async {
      await _pump(tester, 'fr', HelpArticleScreen(article: HelpContent.byId('start')!));
      await tester.tap(find.bySemanticsLabel('Langue de l\'interface').first);
      await tester.pumpAndSettle();
      expect(find.text('Choisissez Français ou Kiswahili. La Bible et les cantiques suivent la langue.'), findsOneWidget);
      expect(find.text('Ouvrir cet écran dans l\'application'), findsOneWidget);
      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();
      expect(find.text('Choisissez Français ou Kiswahili. La Bible et les cantiques suivent la langue.'), findsNothing);
    });

    testWidgets('le bouton d\'agrandissement ouvre la capture en grand, qu\'on peut fermer', (tester) async {
      await _pump(tester, 'fr', HelpArticleScreen(article: HelpContent.byId('start')!));
      await tester.tap(find.byTooltip('Agrandir la capture'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpShotViewer), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpShotViewer), findsNothing);
    });

    testWidgets('en swahili la capture est celle en swahili', (tester) async {
      await _pump(tester, 'sw', HelpArticleScreen(article: HelpContent.byId('start')!));
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Lugha ya programu').first);
      await tester.pump();
      expect(find.textContaining('Chagua Kifaransa au Kiswahili'), findsOneWidget);
    });

    testWidgets('sans capture dans la langue, l\'étape s\'affiche sans image', (tester) async {
      // La Bible annotée n'existe qu'en français : pas de capture en swahili.
      await _pump(tester, 'sw', HelpArticleScreen(article: HelpContent.byId('annotated')!));
      expect(find.byType(Image), findsNothing);
      expect(find.textContaining('Fungua kichupo cha Biblia'), findsOneWidget);
    });

    testWidgets('le « ? » ouvre l\'article demandé et disparaît si l\'article n\'existe pas', (tester) async {
      await _pump(tester, 'fr', const Scaffold(body: Column(children: [HelpButton('backup'), HelpButton('inconnu')])));
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();
      expect(find.byType(HelpArticleScreen), findsOneWidget);
      expect(find.text('Sauvegarder mes données'), findsWidgets);
    });
  });
}
