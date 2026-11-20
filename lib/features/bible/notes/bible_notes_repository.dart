import '../../../core/database/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, visibleForTesting;
import 'package:sqflite/sqflite.dart';

import '../../../core/database/platform/db_platform.dart' as platform;
import 'bible_note.dart';

/// Les notes de commentaire (par exemple celles de la Bible annotée).
///
/// Elles vivent dans leur propre base, `assets/db/bible_notes.db`, copiée sur
/// l'appareil au premier usage. Sans notes pour une version, [forChapter] ne
/// renvoie rien et l'écran de lecture reste celui des autres versions.
class BibleNotesRepository {
  static const _fileName = 'bible_notes.db';
  static Future<Database>? _db;
  static final Map<String, bool> _installed = {};

  /// Pour les tests : ouvre une base en mémoire au lieu du fichier.
  @visibleForTesting
  static Future<Database> Function()? opener;

  /// Pour les tests de la copie depuis les ressources : où écrire le fichier,
  /// et d'où lire la base livrée.
  @visibleForTesting
  static Future<String> Function(String fileName)? pathFor;
  @visibleForTesting
  static Future<ByteData> Function(String key)? assetLoader;

  @visibleForTesting
  static Future<void> resetForTests() async {
    final db = await _db;
    await db?.close();
    _db = null;
    _installed.clear();
  }

  static Future<Database> _open() => _db ??= (opener ?? _openFile)();

  /// À augmenter quand `assets/db/bible_notes.db` change : les appareils
  /// déjà installés reçoivent alors la nouvelle copie.
  static const _assetVersion = 1;
  static const _kAssetVersionPref = 'bibleNotes.assetVersion';

  static Future<Database> _openFile() async {
    // Choisit le moteur SQLite de la plateforme avant tout accès au fichier.
    await DbHelper.ensureFactory();
    final path = await (pathFor ?? platform.getDatabasePath)(_fileName);
    final prefs = await SharedPreferences.getInstance();
    final exists = await databaseFactory.databaseExists(path);
    if (!exists || (prefs.getInt(_kAssetVersionPref) ?? 0) < _assetVersion) {
      final data = await (assetLoader ?? rootBundle.load)('assets/db/$_fileName');
      if (exists) await databaseFactory.deleteDatabase(path);
      await databaseFactory.writeDatabaseBytes(
          path, data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      await prefs.setInt(_kAssetVersionPref, _assetVersion);
    }
    return databaseFactory.openDatabase(path);
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
