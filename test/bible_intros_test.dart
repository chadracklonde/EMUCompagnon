import 'dart:io';

import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/bible/notes/bible_note.dart';
import 'package:emu_compagnon/features/bible/notes/book_intro_screen.dart';
import 'package:emu_compagnon/features/bible/notes/note_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  group('introductions livrées (assets/db/bible_notes.db)', () {
    late Database db;
    setUpAll(() async {
      final copy = File('${Directory.systemTemp.path}/ba_intros_test.db');
      File('assets/db/bible_notes.db').copySync(copy.path);
      db = await factory.openDatabase(copy.path,
          options: OpenDatabaseOptions(readOnly: true));
    });
    tearDownAll(() => db.close());

    Future<List<String>> titles(String book) async => [
          for (final r in await db.query('book_intros',
              where: "version = 'BA' AND book = ?",
              whereArgs: [book],
              orderBy: 'position'))
            r['title'] as String
        ];

    test('71 liens livre → introduction, tous les livres cités existent', () async {
      final n = await db.rawQuery('SELECT COUNT(*) c FROM book_intros');
      expect(n.single['c'], 71);
      final books = await db.rawQuery(
          'SELECT DISTINCT book FROM book_intros ORDER BY book');
      // Les 66 livres ont au moins un texte, sauf ceux couverts par un texte commun
      // (ils en ont aussi un : Samuel, Rois, Chroniques, Néhémie, 3 Jean).
      expect(books.length, greaterThanOrEqualTo(60));
    });

    test('Genèse : trois textes dans l\'ordre ; Job : trois ; Jonas : un', () async {
      expect(await titles('Genèse'), [
        'Introduction à la Bible',
        'Introduction au Pentateuque',
        'Étude sur la Création (F. Godet)',
      ]);
      expect((await titles('Job')).length, 3);
      expect(await titles('Jonas'), ['Introduction à Jonas']);
      expect(await titles('2 Samuel'), await titles('1 Samuel'));
    });

    test('balisage propre : seulement p, i, b, h, ref, ul, li, br, aucun << ni &', () async {
      final rows = await db.query('book_intros', columns: ['html']);
      final allowed = RegExp(r'^/?(p|i|b|h|ref|ul|li|br)$');
      for (final r in rows) {
        final html = r['html'] as String;
        expect(html.contains('<<'), isFalse);
        expect(html.contains('&'), isFalse, reason: html.substring(0, 80));
        for (final m in RegExp(r'<([^>]*)>').allMatches(html)) {
          expect(allowed.hasMatch(m.group(1)!), isTrue, reason: m.group(0));
        }
        // chaque balise ouverte est refermée
        for (final t in ['p', 'i', 'b', 'h', 'ref', 'ul', 'li']) {
          expect('<$t>'.allMatches(html).length, '</$t>'.allMatches(html).length,
              reason: t);
        }
      }
    });

    test('un texte réel : Jonas parle de la colombe et de Gath-Hépher', () async {
      final r = await db.query('book_intros',
          where: "book = 'Jonas'", columns: ['html']);
      final html = r.single['html'] as String;
      expect(html, contains('signifie colombe'));
      expect(html, contains('Gath-Hépher'));
      expect(html, contains('« Jéroboam rétablit'));
    });
  });

  group('lecture', () {
    test('chunks coupe après chaque paragraphe, titre et liste', () {
      final c = IntroReaderScreen.chunks(
          '<h>I</h><p>Un</p><p>Deux</p><ul><li>a</li><li>b</li></ul><p>Trois</p>');
      expect(c, ['<h>I</h>', '<p>Un</p>', '<p>Deux</p>', '<ul><li>a</li><li>b</li></ul>', '<p>Trois</p>']);
    });

    testWidgets('IntroReaderScreen affiche titre, intertitre et texte', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.load();
      await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: const MaterialApp(
          home: IntroReaderScreen(
            version: 'BA',
            book: 'Jonas',
            intro: BookIntro(
                id: 'x',
                title: 'Introduction à Jonas',
                html: '<h>I La personne</h><p>Le mot <i>Jona</i> signifie colombe.</p>'),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Introduction à Jonas'), findsOneWidget);
      expect(find.textContaining('signifie colombe', findRichText: true), findsOneWidget);
      expect(find.textContaining('La personne', findRichText: true), findsOneWidget);
      expect(find.byType(NoteText), findsWidgets);
    });

    testWidgets('BookIntroEntry reste invisible pour Louis Segond', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.load();
      await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: const MaterialApp(
            home: Scaffold(body: BookIntroEntry(book: 'Jonas', version: 'LSG1910'))),
      ));
      await tester.pump();
      expect(find.byType(ListTile), findsNothing);
    });
  });
}
