import 'dart:io';

import 'package:emu_compagnon/core/models/bible_version.dart';
import 'package:emu_compagnon/features/bible/notes/bible_notes_repository.dart';
import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/bible/notes/notes_widgets.dart';
import 'package:emu_compagnon/shared/widgets/verse_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  group('texte livré (assets/db/app_data.db)', () {
    late Database db;
    setUpAll(() async {
      final copy = File('${Directory.systemTemp.path}/ba_text_test.db');
      File('assets/db/app_data.db').copySync(copy.path);
      db = await factory.openDatabase(copy.path, options: OpenDatabaseOptions(readOnly: true));
    });
    tearDownAll(() => db.close());

    test('31 173 versets BA sur 1 189 chapitres, et les autres versions ne changent pas', () async {
      final counts = {
        for (final r in await db.rawQuery('SELECT version, COUNT(*) c FROM bible_verses GROUP BY version'))
          r['version']: r['c']
      };
      expect(counts, {'BA': 31173, 'LSG1910': 31102, 'SCV': 31102});
      final chapters = await db.rawQuery(
          "SELECT COUNT(*) c FROM (SELECT DISTINCT book, chapter FROM bible_verses WHERE version = 'BA')");
      expect(chapters.single['c'], 1189);
    });

    test('Jean 3.16 et les livres portent les noms et numéros de Louis Segond', () async {
      final r = await db.rawQuery(
          "SELECT text, book_num FROM bible_verses WHERE version = 'BA' AND book = 'Jean' AND chapter = 3 AND verse = 16");
      expect(r.single['text'],
          "Car Dieu a tellement aimé le monde, qu'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu'il ait la vie éternelle.");
      final mismatch = await db.rawQuery('''
        SELECT COUNT(*) c FROM bible_verses b JOIN bible_verses l
          ON l.version = 'LSG1910' AND l.book = b.book AND l.chapter = 1 AND l.verse = 1
        WHERE b.version = 'BA' AND b.chapter = 1 AND b.verse = 1 AND b.book_num <> l.book_num''');
      expect(mismatch.single['c'], 0);
    });

    test('le texte accentué est complet : œ, é, À, guillemets', () async {
      final r = await db.rawQuery(
          "SELECT COUNT(*) c FROM bible_verses WHERE version = 'BA' AND text LIKE '%œ%'");
      expect(r.single['c'] as int, greaterThan(1000));
      final bad = await db.rawQuery(
          "SELECT COUNT(*) c FROM bible_verses WHERE version = 'BA' AND (text LIKE '%<%' OR text LIKE '%&nbsp;%' OR text = '')");
      expect(bad.single['c'], 0);
    });

    test('la recherche trouve les mots de la Bible annotée', () async {
      final r = await db.rawQuery('''
        SELECT v.version FROM bible_verses_fts f JOIN bible_verses v ON v.id = f.rowid
        WHERE bible_verses_fts MATCH 'tellement' AND v.book = 'Jean' AND v.chapter = 3 AND v.verse = 16''');
      expect(r.map((e) => e['version']), contains('BA'));
    });
  });

  group('notes livrées (assets/db/bible_notes.db)', () {
    late Database notes;
    late Database text;
    setUpAll(() async {
      final c1 = File('${Directory.systemTemp.path}/ba_notes_test.db');
      File('assets/db/bible_notes.db').copySync(c1.path);
      notes = await factory.openDatabase(c1.path, options: OpenDatabaseOptions(readOnly: true));
      final c2 = File('${Directory.systemTemp.path}/ba_text_test2.db');
      File('assets/db/app_data.db').copySync(c2.path);
      text = await factory.openDatabase(c2.path, options: OpenDatabaseOptions(readOnly: true));
    });
    tearDownAll(() async {
      await notes.close();
      await text.close();
    });

    test('23 299 notes, avec celles de Jean 3.16', () async {
      final n = await notes.rawQuery("SELECT COUNT(*) c FROM bible_notes WHERE version = 'BA'");
      expect(n.single['c'], 23299);
      final r = await notes.rawQuery(
          "SELECT html FROM bible_notes WHERE version='BA' AND book='Jean' AND chapter=3 AND verse=16");
      expect(r.single['html'] as String, contains('Il y a dans cette parole plus à adorer'));
    });

    test('chaque note appartient à un chapitre qui existe dans le texte', () async {
      final chapters = {
        for (final r in await text.rawQuery(
            "SELECT DISTINCT book, chapter FROM bible_verses WHERE version = 'BA'"))
          '${r['book']}|${r['chapter']}'
      };
      final used = await notes.rawQuery('SELECT DISTINCT book, chapter FROM bible_notes');
      final missing = [for (final r in used) '${r['book']}|${r['chapter']}'].where((k) => !chapters.contains(k));
      expect(missing, isEmpty);
    });
  });

  group('copie des notes livrées sur l\'appareil', () {
    late Directory dir;
    var copies = 0;
    setUp(() async {
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({});
      dir = Directory.systemTemp.createTempSync('ba_notes_copy');
      copies = 0;
      await BibleNotesRepository.resetForTests();
      BibleNotesRepository.opener = null;
      BibleNotesRepository.pathFor = (name) async => '${dir.path}/$name';
      BibleNotesRepository.assetLoader = (key) async {
        copies++;
        final bytes = File(key).readAsBytesSync();
        return ByteData.view(bytes.buffer);
      };
    });
    tearDown(() async {
      await BibleNotesRepository.resetForTests();
      BibleNotesRepository.pathFor = null;
      BibleNotesRepository.assetLoader = null;
      dir.deleteSync(recursive: true);
    });

    test('première ouverture : la base est copiée et les notes de Jean 3 se lisent', () async {
      expect(await BibleNotesRepository.isInstalled('BA'), isTrue);
      final c = await BibleNotesRepository.forChapter('BA', 'Jean', 3, 36);
      expect(c.isEmpty, isFalse);
      expect(c.coveringVerse(16)!.html, contains('plus à adorer'));
      expect(copies, 1);
    });

    test('les ouvertures suivantes ne recopient pas la base, une version plus récente la remplace', () async {
      await BibleNotesRepository.isInstalled('BA');
      await BibleNotesRepository.resetForTests();
      await BibleNotesRepository.isInstalled('BA');
      expect(copies, 1);
      // Une copie livrée plus récente (le numéro enregistré est plus ancien) est recopiée.
      SharedPreferences.setMockInitialValues({'bibleNotes.assetVersion': 0});
      await BibleNotesRepository.resetForTests();
      await BibleNotesRepository.isInstalled('BA');
      expect(copies, 2);
    });

    test('une version sans notes ne renvoie rien', () async {
      expect((await BibleNotesRepository.forChapter('LSG1910', 'Jean', 3, 36)).isEmpty, isTrue);
    });
  });

  group('crédit et choix', () {
    Future<void> pump(WidgetTester tester, Widget child, {String locale = 'fr'}) async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.load();
      await settings.setLocale(locale);
      await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: MaterialApp(home: Scaffold(body: child)),
      ));
      await tester.pump();
    }

    testWidgets('la Bible annotée affiche son crédit avec le lien theotex.org', (tester) async {
      await pump(tester, const VersionCredit(version: BibleVersions.annotee));
      expect(find.textContaining('ThéoTeX (Claude Royère)'), findsOneWidget);
      expect(find.textContaining('theotex.org'), findsOneWidget);
    });

    testWidgets('Louis Segond n\'affiche aucun crédit', (tester) async {
      await pump(tester, const VersionCredit(version: BibleVersions.lsg1910));
      expect(find.textContaining('theotex'), findsNothing);
    });

    test('le verset partagé cite la source', () {
      expect(VerseShareCard.sourceForBible('BA'), 'La Bible annotée · theotex.org');
      expect(VerseShareCard.sourceForBible('LSG1910'), 'Louis Segond 1910');
      expect(VerseShareCard.sourceForBible('SCV'), contains('CC BY-SA 4.0'));
    });

    test('choisir « français » garde la Bible annotée, mais quitter le swahili revient à Louis Segond', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppSettings();
      await s.load();
      await s.setBibleVersion('BA');
      expect(s.locale, 'fr');
      await s.setLocale('fr');
      expect(s.bibleVersion, 'BA');
      await s.setLocale('sw');
      expect(s.bibleVersion, 'SCV');
      await s.setLocale('fr');
      expect(s.bibleVersion, 'LSG1910');
    });
  });
}
