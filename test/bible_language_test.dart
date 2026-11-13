import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/bible/repository/bible_repository.dart';
import 'package:emu_compagnon/features/bible/screens/books_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettings> _settings(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final s = AppSettings();
  await s.load();
  return s;
}

void main() {
  group('la langue et la version de la Bible vont ensemble', () {
    test('choisir le swahili met aussi la Bible swahilie', () async {
      final s = await _settings({});
      expect((s.locale, s.bibleVersion), ('fr', 'LSG1910'));
      await s.setLocale('sw');
      expect((s.locale, s.bibleVersion), ('sw', 'SCV'));
      expect(BibleRepository.activeVersion, 'SCV');
      await s.setLocale('fr');
      expect((s.locale, s.bibleVersion), ('fr', 'LSG1910'));
      expect(BibleRepository.activeVersion, 'LSG1910');
    });

    test('choisir la Bible swahilie met aussi l\'application en swahili', () async {
      final s = await _settings({});
      await s.setBibleVersion('SCV');
      expect((s.locale, s.bibleVersion), ('sw', 'SCV'));
      await s.setBibleVersion('LSG1910');
      expect((s.locale, s.bibleVersion), ('fr', 'LSG1910'));
    });

    test('au démarrage, le swahili choisi à un endroit vaut pour les deux', () async {
      var s = await _settings({'settings.locale': 'fr', 'settings.bibleVersion': 'SCV'});
      expect((s.locale, s.bibleVersion), ('sw', 'SCV'));
      s = await _settings({'settings.locale': 'sw', 'settings.bibleVersion': 'LSG1910'});
      expect((s.locale, s.bibleVersion), ('sw', 'SCV'));
      expect(BibleRepository.activeVersion, 'SCV');
      s = await _settings({});
      expect(BibleRepository.activeVersion, 'LSG1910');
    });

    test('la langue est enregistrée avec la version', () async {
      final s = await _settings({});
      await s.setLocale('sw');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings.locale'), 'sw');
      expect(prefs.getString('settings.bibleVersion'), 'SCV');
    });
  });

  testWidgets('la liste des livres change de langue avec le choix de la langue', (tester) async {
    final settings = await _settings({});
    await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: const MaterialApp(home: BooksScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Genèse'), findsOneWidget);
    expect(find.byTooltip('Version de la Bible'), findsOneWidget);
    expect(find.text('Mwanzo'), findsNothing);

    await settings.setLocale('sw');
    await tester.pumpAndSettle();
    expect(find.text('Mwanzo'), findsOneWidget);
    expect(find.text('Genèse'), findsNothing);
    expect(find.byTooltip('Toleo la Biblia'), findsOneWidget);

    // Le choix fait dans l'écran de la Bible va dans l'autre sens.
    await settings.setBibleVersion('LSG1910');
    await tester.pumpAndSettle();
    expect(find.text('Genèse'), findsOneWidget);
    expect(settings.locale, 'fr');
  });

  testWidgets('le sélecteur de version est dans la langue choisie', (tester) async {
    final settings = await _settings({'settings.locale': 'sw'});
    await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: const MaterialApp(home: BooksScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Toleo la Biblia'));
    await tester.pumpAndSettle();
    expect(find.text('Toleo la Biblia'), findsWidgets);
    expect(find.text('Hivi karibuni'), findsOneWidget);
  });
}
