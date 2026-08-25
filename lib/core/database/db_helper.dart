import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Handles opening the pre-populated SQLite database bundled as an asset.
/// On first launch, copies `assets/db/app_data.db` into the app's documents
/// directory so sqflite can open it read/write (needed for bookmarks).
class DbHelper {
  static Database? _db;
  static const _dbFileName = 'app_data.db';

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, _dbFileName);

    final exists = await File(dbPath).exists();
    if (!exists) {
      final data = await rootBundle.load('assets/db/$_dbFileName');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(dbPath).writeAsBytes(bytes, flush: true);
    }

    return openDatabase(dbPath);
  }

  /// Useful during development if the bundled DB is updated and you want
  /// to force a fresh copy on next launch.
  static Future<void> resetDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, _dbFileName);
    if (await File(dbPath).exists()) {
      await File(dbPath).delete();
    }
    _db = null;
  }

  /// Merges a freshly downloaded content database (Bible/hymns/dictionary)
  /// into the live one, WITHOUT touching the user's personal data
  /// (bookmarks, notes, highlights) — those tables are never referenced
  /// here, so they survive untouched. Used by the content-update feature.
  static Future<void> mergeContentUpdate(String newDbPath) async {
    final db = await database;
    await db.execute("ATTACH DATABASE '$newDbPath' AS newdb");
    try {
      await db.transaction((txn) async {
        for (final table in ['bible_verses', 'hymns', 'dictionary_entries']) {
          await txn.execute('DELETE FROM $table');
          await txn.execute('INSERT INTO $table SELECT * FROM newdb.$table');
        }
        // Rebuild the FTS5 indexes to match the refreshed content.
        await txn.execute('DELETE FROM bible_verses_fts');
        await txn.execute(
          'INSERT INTO bible_verses_fts(rowid, text) SELECT id, text FROM bible_verses',
        );
        await txn.execute('DELETE FROM hymns_fts');
        await txn.execute(
          'INSERT INTO hymns_fts(rowid, title, lyrics) SELECT id, title, lyrics FROM hymns',
        );
        await txn.execute('DELETE FROM dictionary_fts');
        await txn.execute(
          'INSERT INTO dictionary_fts(rowid, term, definition) SELECT id, term, definition FROM dictionary_entries',
        );
      });
    } finally {
      await db.execute('DETACH DATABASE newdb');
    }
  }
}
