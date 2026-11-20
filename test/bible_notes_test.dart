import 'dart:convert';

import 'package:emu_compagnon/core/models/bible_version.dart';
import 'package:emu_compagnon/core/models/verse.dart';
import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/bible/notes/bible_note.dart';
import 'package:emu_compagnon/features/bible/notes/bible_notes_repository.dart';
import 'package:emu_compagnon/features/bible/notes/note_text.dart';
import 'package:emu_compagnon/features/bible/notes/notes_mode.dart';
import 'package:emu_compagnon/features/bible/notes/notes_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Les notes de ces tests sont inventées : aucun texte de la Bible annotée.
BibleNote _n(int verse, String html) =>
    BibleNote(version: 'BA', book: 'Jean', chapter: 3, verse: verse, html: html);

Verse _v(int n) => Verse(
    id: n, book: 'Jean', bookNum: 43, chapter: 3, verse: n, text: 'Texte du verset $n.', version: 'BA');

Future<void> _pump(WidgetTester tester, Widget child) async {
  SharedPreferences.setMockInitialValues({});
  final settings = AppSettings();
  await settings.load();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(420, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
    value: settings,
    child: MaterialApp(home: Scaffold(body: child)),
  ));
  await tester.pump();
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('rangement des notes', () {
    test('une note commente les versets qui suivent la précédente, jusqu\'à son verset', () {
      final c = ChapterNotes.build([_n(15, 'a'), _n(16, 'b'), _n(21, 'c')], verseCount: 21);
      expect([for (final g in c.groups) g.range], ['1-15', '16', '17-21']);
      expect(c.coveringVerse(14)!.html, 'a');
      expect(c.coveringVerse(20)!.html, 'c');
      expect(c.endingAt(16).single.html, 'b');
      expect(c.endingAt(14), isEmpty);
    });

    test('le verset 0 est une introduction, pas une note de verset', () {
      final c = ChapterNotes.build([_n(0, 'intro'), _n(3, 'x')], verseCount: 5);
      expect(c.intros, ['intro']);
      expect(c.groups.single.range, '1-3');
    });

    test('un numéro hors du chapitre (faute de la source) est ramené au dernier verset', () {
      final c = ChapterNotes.build([_n(2, 'a'), _n(99, 'b')], verseCount: 5);
      expect([for (final g in c.groups) g.range], ['1-2', '3-5']);
    });

    test('deux notes sur le même verset restent deux notes, dans l\'ordre de lecture', () {
      final c = ChapterNotes.build([_n(4, 'première'), _n(4, 'seconde')], verseCount: 6);
      expect([for (final g in c.groups) g.html], ['première', 'seconde']);
      expect(c.endingAt(4).length, 2);
    });

    test('sans note ou sans verset, le chapitre est vide', () {
      expect(ChapterNotes.build([], verseCount: 5).isEmpty, isTrue);
      expect(ChapterNotes.build([_n(1, 'a')], verseCount: 0).isEmpty, isTrue);
    });
  });

  group('lecture d\'une note', () {
    test('paragraphes, italique, gras, titre, référence et puces', () {
      final blocks = parseNote(
          '<p><h>Titre</h></p><p>Un <i>mot</i> et <b>un autre</b> (<ref>Jean 3.16</ref>).</p>'
          '<ul><li>premier</li><li>second</li></ul>');
      expect(blocks.map((b) => b.plain), ['Titre', 'Un mot et un autre (Jean 3.16).', 'premier', 'second']);
      expect(blocks[0].runs.single.heading, isTrue);
      expect(blocks[1].runs[1].italic, isTrue);
      expect(blocks[1].runs[3].bold, isTrue);
      expect(blocks[1].runs[5].ref, isTrue);
      expect(blocks[2].bullet && blocks[3].bullet, isTrue);
      expect(blocks[1].bullet, isFalse);
    });

    test('le texte qui précède le premier paragraphe reste lisible, les entités sont décodées', () {
      final blocks = parseNote('Début &amp; suite<p>Deuxième&nbsp;paragraphe</p>');
      expect(blocks.map((b) => b.plain), ['Début & suite', 'Deuxième paragraphe']);
    });

    test('une note sans balise reste un seul paragraphe', () {
      expect(parseNote('Juste du texte.').single.plain, 'Juste du texte.');
      expect(parseNote(''), isEmpty);
    });
  });

  group('pack de notes installé', () {
    setUp(() async {
      await BibleNotesRepository.resetForTests();
      BibleNotesRepository.opener = () => databaseFactoryFfi.openDatabase(
            inMemoryDatabasePath,
            options: OpenDatabaseOptions(version: 1, onCreate: BibleNotesRepository.createSchema),
          );
    });
    tearDown(() async {
      await BibleNotesRepository.resetForTests();
      BibleNotesRepository.opener = null;
    });

    String pack(List<Map<String, Object>> notes) => jsonEncode(notes);

    test('sans pack, aucune note et la version n\'est pas « installée »', () async {
      expect(await BibleNotesRepository.isInstalled('BA'), isFalse);
      expect((await BibleNotesRepository.forChapter('BA', 'Jean', 3, 21)).isEmpty, isTrue);
    });

    test('installer un pack, lire un chapitre, le remplacer, le supprimer', () async {
      final n = await BibleNotesRepository.installFromJson(
        'BA',
        pack([
          {'book': 'Jean', 'chapter': 3, 'verse': 0, 'html': '<p>Intro</p>'},
          {'book': 'Jean', 'chapter': 3, 'verse': 16, 'html': '<p>Seize</p>'},
          {'book': 'Jean', 'chapter': 4, 'verse': 1, 'html': '<p>Autre chapitre</p>'},
        ]),
      );
      expect(n, 3);
      expect(await BibleNotesRepository.isInstalled('BA'), isTrue);
      final c = await BibleNotesRepository.forChapter('BA', 'Jean', 3, 36);
      expect(c.intros, ['<p>Intro</p>']);
      expect(c.groups.single.range, '1-16');

      // Un autre pack du même nom remplace le premier.
      await BibleNotesRepository.installFromJson(
          'BA', pack([{'book': 'Jean', 'chapter': 3, 'verse': 2, 'html': 'neuf'}]));
      final c2 = await BibleNotesRepository.forChapter('BA', 'Jean', 3, 36);
      expect(c2.groups.single.html, 'neuf');
      expect((await BibleNotesRepository.forChapter('BA', 'Jean', 4, 5)).isEmpty, isTrue);

      await BibleNotesRepository.remove('BA');
      expect(await BibleNotesRepository.isInstalled('BA'), isFalse);
    });

    test('les entrées illisibles du pack sont ignorées', () async {
      final n = await BibleNotesRepository.installFromJson(
          'BA',
          pack([
            {'book': 'Jean', 'chapter': 3, 'verse': 1, 'html': 'bon'},
            {'book': 'Jean', 'chapter': 'x', 'verse': 1, 'html': 'mauvais'},
          ]));
      expect(n, 1);
    });
  });

  group('version et mode', () {
    test('la Bible annotée est reconnue mais pas encore dans le choix de version', () {
      expect(BibleVersions.byCode('BA').hasNotes, isTrue);
      expect(BibleVersions.all.map((v) => v.code), isNot(contains('BA')));
      expect(BibleVersions.byCode('LSG1910').hasNotes, isFalse);
      expect(BibleVersions.byCode('SCV').hasNotes, isFalse);
    });

    test('le mode choisi est retenu, Texte par défaut', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await NotesMode.load(), NotesMode.text);
      await NotesMode.study.save();
      expect(await NotesMode.load(), NotesMode.study);
      SharedPreferences.setMockInitialValues({'bible.notesMode': 'n_importe_quoi'});
      expect(await NotesMode.load(), NotesMode.text);
    });
  });

  group('affichage', () {
    testWidgets('le sélecteur propose les trois modes et prévient du choix', (tester) async {
      NotesMode? chosen;
      await _pump(tester, NotesModeBar(mode: NotesMode.text, onChanged: (m) => chosen = m));
      expect(find.text('Texte'), findsOneWidget);
      expect(find.text('Étude'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(tester.getSize(find.byType(SegmentedButton<NotesMode>)).height, greaterThanOrEqualTo(48));
      await tester.tap(find.text('Notes'));
      expect(chosen, NotesMode.notes);
    });

    testWidgets('mode Étude : une note courte n\'a pas de « Lire la suite », une longue se déplie', (tester) async {
      await _pump(tester, const StudyNoteCard(html: '<p>Courte.</p>'));
      expect(find.text('Lire la suite'), findsNothing);

      await _pump(
          tester,
          StudyNoteCard(html: '<p>Premier paragraphe.</p><p>Second paragraphe.</p>'));
      expect(find.text('Lire la suite'), findsOneWidget);
      expect(find.text('Second paragraphe.'), findsNothing);
      await tester.tap(find.text('Lire la suite'));
      await tester.pump();
      expect(find.text('Second paragraphe.'), findsOneWidget);
      expect(find.text('Réduire'), findsOneWidget);
      await tester.tap(find.text('Réduire'));
      await tester.pump();
      expect(find.text('Second paragraphe.'), findsNothing);
    });

    testWidgets('mode Notes : citation, note, et renvoi au verset', (tester) async {
      int? shown;
      final notes = ChapterNotes.build([_n(0, '<p>Introduction.</p>'), _n(2, '<p>Note un.</p>'), _n(3, '<p>Note deux.</p>')],
          verseCount: 3);
      await _pump(
        tester,
        BibleNotesView(
          notes: notes,
          verses: [_v(1), _v(2), _v(3)],
          titleFor: (r) => 'Jean 3.$r',
          onShowVerse: (v) => shown = v,
        ),
      );
      expect(find.text('INTRODUCTION'), findsOneWidget);
      expect(find.text('Jean 3.1-2'), findsOneWidget);
      expect(find.text('Jean 3.3'), findsOneWidget);
      expect(find.textContaining('Texte du verset 1.'), findsOneWidget);
      expect(find.text('Note un.'), findsOneWidget);
      await tester.tap(find.text('Voir dans le texte').last);
      expect(shown, 3);
    });

    testWidgets('en swahili, les textes de l\'interface suivent la langue', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.load();
      await settings.setLocale('sw');
      await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: MaterialApp(home: Scaffold(body: NotesModeBar(mode: NotesMode.text, onChanged: (_) {}))),
      ));
      await tester.pump();
      expect(find.text('Maandishi'), findsOneWidget);
      expect(find.text('Funzo'), findsOneWidget);
      expect(find.text('Madokezo'), findsOneWidget);
    });
  });
}
