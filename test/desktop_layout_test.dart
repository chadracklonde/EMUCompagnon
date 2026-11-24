import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/bible/screens/books_screen.dart';
import 'package:emu_compagnon/features/help/screens/help_article_screen.dart';
import 'package:emu_compagnon/features/help/screens/help_screen.dart';
import 'package:emu_compagnon/features/home/screens/home_screen.dart';
import 'package:emu_compagnon/features/more/screens/more_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Écrans adaptés à l'ordinateur (Mac, Windows) : au-delà de 840 px de large,
/// la mise en page change ; sur téléphone, elle reste celle d'avant.
Future<void> _pump(WidgetTester tester, Size size, Widget home) async {
  SharedPreferences.setMockInitialValues({});
  final s = AppSettings();
  await s.load();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
      value: s, child: MaterialApp(home: home)));
  await tester.pump(const Duration(milliseconds: 300));
}

const _desktop = Size(1280, 800);
const _phone = Size(390, 844);

void main() {
  group('Bible : Ancien et Nouveau Testament', () {
    testWidgets('côte à côte sur ordinateur', (tester) async {
      await _pump(tester, _desktop, const BooksScreen());
      final at = tester.getTopLeft(find.text('Ancien Testament').last);
      final nt = tester.getTopLeft(find.text('Nouveau Testament').last);
      expect(nt.dy, at.dy, reason: 'même hauteur');
      expect(nt.dx, greaterThan(at.dx + 200), reason: 'deux colonnes');
    });

    testWidgets('l\'un sous l\'autre sur téléphone', (tester) async {
      await _pump(tester, _phone, const BooksScreen());
      expect(find.text('Ancien Testament'), findsWidgets);
      // Le Nouveau Testament est plus bas, hors de l'écran : une seule colonne.
      expect(find.text('Nouveau Testament'), findsNothing);
    });

    testWidgets('avec un seul testament, une colonne même sur ordinateur', (tester) async {
      await _pump(tester, _desktop, const BooksScreen(filter: TestamentFilter.oldTestament));
      expect(find.text('Genèse'), findsOneWidget);
      expect(find.text('Matthieu'), findsNothing);
    });
  });

  group('Plus', () {
    testWidgets('deux colonnes sur ordinateur', (tester) async {
      await _pump(tester, _desktop, const MoreScreen());
      final left = tester.getTopLeft(find.text('Bibliothèque'));
      final right = tester.getTopLeft(find.text('Application'));
      expect(right.dy, left.dy);
      expect(right.dx, greaterThan(left.dx + 200));
    });

    testWidgets('une colonne sur téléphone', (tester) async {
      await _pump(tester, _phone, const MoreScreen());
      final left = tester.getTopLeft(find.text('Bibliothèque'));
      expect(left.dx, lessThan(60));
      await tester.scrollUntilVisible(find.text('Application'), 300,
          scrollable: find.byType(Scrollable).first);
      final right = tester.getTopLeft(find.text('Application'));
      expect(right.dx, left.dx);
    });
  });

  group('Aide', () {
    testWidgets('liste à gauche et article à droite sur ordinateur, sans changer de page', (tester) async {
      await _pump(tester, _desktop, const HelpScreen());
      // Le premier sujet est déjà affiché à droite, avec son titre en tête.
      expect(find.byType(HelpArticleBody), findsOneWidget);
      expect(find.text('Bien commencer'), findsWidgets);
      await tester.tap(find.text('La Bible annotée'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpArticleScreen), findsNothing, reason: 'pas de nouvelle page');
      expect(find.byType(HelpArticleBody), findsOneWidget);
      expect(find.textContaining('commentaires des auteurs de Neuchâtel'), findsOneWidget);
      // Le titre du sujet est repris en tête du contenu (pas de barre propre à l'article).
      expect(find.text('La Bible annotée'), findsNWidgets(2));
    });

    testWidgets('sur téléphone, un sujet ouvre une nouvelle page', (tester) async {
      await _pump(tester, _phone, const HelpScreen());
      expect(find.byType(HelpArticleBody), findsNothing);
      await tester.tap(find.text('La Bible annotée'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpArticleScreen), findsOneWidget);
    });
  });

  group('Accueil', () {
    testWidgets('les quatre accès sur une seule rangée sur ordinateur', (tester) async {
      await _pump(tester, _desktop, const HomeScreen());
      await tester.scrollUntilVisible(find.text('Liturgie'), 300,
          scrollable: find.byType(Scrollable).first);
      final ys = {
        for (final t in ['Ancien Testament', 'Nouveau Testament', 'Chants de Victoire', 'Liturgie'])
          t: tester.getTopLeft(find.text(t).last).dy,
      };
      final hauts = ys.values.toList()..sort();
      expect(hauts.last - hauts.first, lessThan(40), reason: 'même rangée : $ys');
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('2 × 2 sur téléphone', (tester) async {
      await _pump(tester, _phone, const HomeScreen());
      await tester.scrollUntilVisible(find.text('Liturgie'), 300,
          scrollable: find.byType(Scrollable).first);
      final at = tester.getTopLeft(find.text('Ancien Testament').last).dy;
      final hymns = tester.getTopLeft(find.text('Chants de Victoire').last).dy;
      expect(hymns, greaterThan(at + 50));
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
