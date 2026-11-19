import 'package:emu_compagnon/core/l10n/app_strings.dart';
import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/bible/screens/books_screen.dart';
import 'package:emu_compagnon/features/home/screens/home_screen.dart';
import 'package:emu_compagnon/features/onboarding/screens/language_welcome_screen.dart';
import 'package:emu_compagnon/features/onboarding/screens/onboarding_screen.dart';
import 'package:emu_compagnon/shared/widgets/language_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettings> _settings([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final s = AppSettings();
  await s.load();
  return s;
}

Widget _app(AppSettings settings, Widget home) => ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: MaterialApp(home: home),
    );

void main() {
  group('LanguageSwitch', () {
    testWidgets('bascule la langue, propose d\'annuler, et annule', (tester) async {
      final settings = await _settings();
      await tester.pumpWidget(_app(
        settings,
        const Scaffold(body: Center(child: LanguageSwitch(options: LanguageSwitch.languages, compact: true))),
      ));
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('Kiswahili'), findsOneWidget);

      await tester.tap(find.text('Kiswahili'));
      await tester.pumpAndSettle();
      expect(settings.locale, 'sw');
      expect(settings.bibleVersion, 'SCV');
      expect(find.text('Lugha: Kiswahili'), findsOneWidget);

      await tester.tap(find.text('RUDISHA'));
      await tester.pumpAndSettle();
      expect(settings.locale, 'fr');
      expect(settings.bibleVersion, 'LSG1910');
    });

    testWidgets('les noms de langue ne sont jamais traduits', (tester) async {
      final settings = await _settings({'settings.locale': 'sw'});
      await tester.pumpWidget(_app(
        settings,
        const Scaffold(body: LanguageSwitch(options: LanguageSwitch.languages, compact: true)),
      ));
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('Kiswahili'), findsOneWidget);
    });

    testWidgets('la zone de toucher fait au moins 48 dp de haut, en version compacte comme complète', (tester) async {
      final settings = await _settings();
      await tester.pumpWidget(_app(
        settings,
        const Scaffold(
          body: Column(children: [
            LanguageSwitch(options: LanguageSwitch.languages, compact: true),
            LanguageSwitch(options: LanguageSwitch.hymnals),
          ]),
        ),
      ));
      final sizes = tester.widgetList<LanguageSwitch>(find.byType(LanguageSwitch)).map(
            (w) => tester.getSize(find.byWidget(w)).height,
          );
      expect(sizes.every((h) => h >= 48), isTrue, reason: '$sizes');
    });

    testWidgets('l\'écran de la Bible propose les deux versions et change tout', (tester) async {
      final settings = await _settings();
      await tester.pumpWidget(_app(settings, const BooksScreen()));
      await tester.pumpAndSettle();
      // Le nom de la version est dans le sélecteur, et sous le titre de la barre.
      expect(find.text('Louis Segond 1910'), findsWidgets);
      expect(find.text('Biblia Takatifu Wazi'), findsOneWidget);
      expect(find.text('Genèse'), findsOneWidget);
      await tester.tap(find.text('Biblia Takatifu Wazi'));
      await tester.pumpAndSettle();
      expect(find.text('Mwanzo'), findsOneWidget);
      expect(settings.locale, 'sw');
    });
  });

  group('accueil', () {
    testWidgets('la pastille de langue est sous le verset du jour, et l\'en-tête tient à 360 px en swahili', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final settings = await _settings({'settings.locale': 'sw'});
      await tester.pumpWidget(_app(settings, const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      // Aucun dépassement d'écran (Flutter le signalerait comme une exception).
      expect(tester.takeException(), isNull);
      // Selon l'heure : « Hujambo » ou « Habari za jioni » (le plus long).
      expect(find.text('Hujambo').evaluate().length + find.text('Habari za jioni').evaluate().length, 1);
      // Les quatre icônes de l'en-tête : partage, langue, thème, réglages.
      expect(find.byTooltip('Pendekeza programu'), findsOneWidget);
      expect(find.byTooltip('Lugha'), findsOneWidget);
      expect(find.byType(LanguageSwitch), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('premier lancement', () {
    testWidgets('choisir le swahili met l\'écran et le tutoriel en swahili', (tester) async {
      final settings = await _settings();
      await tester.pumpWidget(_app(settings, const LanguageWelcomeScreen(initialLocale: 'fr')));
      expect(find.text('Karibu · Bienvenue'), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);

      await tester.tap(find.text('Kiswahili'));
      await tester.pump();
      expect(find.text('Endelea'), findsOneWidget);
      expect(find.text('Unaweza kubadilisha baadaye.'), findsOneWidget);

      await tester.tap(find.text('Endelea'));
      await tester.pumpAndSettle();
      expect(settings.locale, 'sw');
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Karibu ÉMU Compagnon'), findsOneWidget);
      expect(find.text('Ruka'), findsOneWidget);
      expect(find.text('Inayofuata'), findsOneWidget);
    });

    testWidgets('le français mène au tutoriel en français', (tester) async {
      final settings = await _settings();
      await tester.pumpWidget(_app(settings, const LanguageWelcomeScreen(initialLocale: 'fr')));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(settings.locale, 'fr');
      expect(find.text('Bienvenue sur ÉMU Compagnon'), findsOneWidget);
      expect(find.text('Passer'), findsOneWidget);
    });

    test('les sept écrans du tutoriel existent en français et en swahili', () {
      for (var i = 1; i <= 7; i++) {
        for (final part in ['title', 'desc']) {
          final key = 'onb${i}_$part';
          final fr = AppStrings.t(key, 'fr');
          final sw = AppStrings.t(key, 'sw');
          expect(fr, isNot(key), reason: 'fr $key');
          expect(sw, isNot(key), reason: 'sw $key');
          expect(sw, isNot(fr), reason: '$key n\'est pas traduit');
        }
      }
    });
  });
}
