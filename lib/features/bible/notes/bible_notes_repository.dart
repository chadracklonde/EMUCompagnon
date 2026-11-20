import 'dart:convert';

import 'package:flutter/foundation.dart' show compute, visibleForTesting;
import 'package:sqflite/sqflite.dart';

import '../../../core/database/platform/db_platform.dart' as platform;
import 'bible_note.dart';

/// Les notes de commentaire (par exemple celles de la Bible annotée).
///
/// Elles ne sont pas dans la base livrée avec l'application : elles
/// viennent d'un « pack » installé à part, dans leur propre fichier. Sans
/// pack, [forChapter] ne renvoie rien et l'écran de lecture reste celui des
/// autres versions.
class BibleNotesRepository {
  static const _fileName = 'bible_notes.db';
  static Future<Database>? _db;
  static final Map<String, bool> _installed = {};

  /// Pour les tests : ouvre une base en mémoire au lieu du fichier.
  @visibleForTesting
  static Future<Database> Function()? opener;

  @visibleForTesting
  static Future<void> resetForTests() async {
    final db = await _db;
    await db?.close();
    _db = null;
    _installed.clear();
  }

  static Future<Database> _open() => _db ??= (opener ?? _openFile)();

  static Future<Database> _openFile() async {
    final path = await platform.getDatabasePath(_fileName);
    return openDatabase(path, version: 1, onCreate: createSchema);
  }

  @visibleForTesting
  static Future<void> createSchema(Database db, [int version = 1]) async {
    await db.execute('''
      CREATE TABLE bible_notes (
        version TEXT NOT NULL,
        book TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        ord INTEGER NOT NULL,
        html TEXT NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX bible_notes_chapter ON bible_notes(version, book, chapter)');
  }

  /// Vrai quand un pack de notes est installé pour [version].
  static Future<bool> isInstalled(String version) async {
    final cached = _installed[version];
    if (cached != null) return cached;
    try {
      final db = await _open();
      final rows = await db.rawQuery(
          'SELECT 1 FROM bible_notes WHERE version = ? LIMIT 1', [version]);
      return _installed[version] = rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Les notes d'un chapitre de [verseCount] versets, rangées par verset.
  static Future<ChapterNotes> forChapter(
      String version, String book, int chapter, int verseCount) async {
    try {
      if (!await isInstalled(version)) return ChapterNotes.empty;
      final db = await _open();
      final rows = await db.query(
        'bible_notes',
        where: 'version = ? AND book = ? AND chapter = ?',
        whereArgs: [version, book, chapter],
        orderBy: 'ord',
      );
      return ChapterNotes.build([
        for (final r in rows)
          BibleNote(
            version: version,
            book: book,
            chapter: chapter,
            verse: r['verse'] as int,
            html: r['html'] as String,
          ),
      ], verseCount: verseCount);
    } catch (_) {
      // Les notes sont un plus : la lecture continue sans elles.
      return ChapterNotes.empty;
    }
  }

  /// Installe (ou remplace) les notes de [version] à partir d'un fichier JSON :
  /// une liste d'objets `{book, chapter, verse, html}`. Renvoie le nombre de
  /// notes installées.
  static Future<int> installFromJson(String version, String jsonText) async {
    final list = await compute(_decode, jsonText);
    final db = await _open();
    await db.transaction((txn) async {
      await txn
          .delete('bible_notes', where: 'version = ?', whereArgs: [version]);
      final batch = txn.batch();
      var ord = 0;
      for (final n in list) {
        batch.insert('bible_notes', {
          'version': version,
          'book': n['book'],
          'chapter': n['chapter'],
          'verse': n['verse'],
          'ord': ord++,
          'html': n['html'],
        });
      }
      await batch.commit(noResult: true);
    });
    _installed[version] = list.isNotEmpty;
    return list.length;
  }

  /// Supprime les notes de [version] (pour libérer de la place).
  static Future<void> remove(String version) async {
    final db = await _open();
    await db.delete('bible_notes', where: 'version = ?', whereArgs: [version]);
    _installed[version] = false;
  }
}

List<Map<String, Object?>> _decode(String text) {
  final raw = jsonDecode(text) as List<dynamic>;
  return [
    for (final e in raw)
      if (e is Map &&
          e['html'] is String &&
          e['chapter'] is int &&
          e['verse'] is int)
        {
          'book': e['book'] as String,
          'chapter': e['chapter'] as int,
          'verse': e['verse'] as int,
          'html': e['html'] as String,
        },
  ];
}
