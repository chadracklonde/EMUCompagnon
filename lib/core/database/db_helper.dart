import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Handles opening the pre-populated SQLite database bundled as an asset.
///
/// IMPORTANT: the local copy on a device is only ever written once, the
/// first time the app runs — after that, sqflite just opens whatever file
/// already exists in the documents directory. If the bundled asset DB is
/// later updated (new content, new tables, fixed search index...), a
/// device that already installed an earlier build would silently keep
/// using its old, stale local copy forever, since "the file already
/// exists" is the only check made. This caused real bugs during testing
/// (search returning no results on devices that had installed an earlier
/// build). [_currentContentVersion] fixes this: it's bumped whenever
/// assets/db/app_data.db changes in a way that needs to reach existing
/// installs, and the app compares it against what was last applied on
/// that device, refreshing content (never personal data) when it's out
/// of date.
class DbHelper {
  static Database? _db;
  static const _dbFileName = 'app_data.db';

  /// Bump this whenever assets/db/app_data.db is regenerated with new or
  /// fixed content/schema that already-installed devices need to receive.
  static const int _currentContentVersion = 2;
  static const _kLastAppliedVersionPref = 'db.lastAppliedContentVersion';

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
      await _copyAssetDbTo(dbPath);
      await _setLastAppliedVersion(_currentContentVersion);
      return openDatabase(dbPath);
    }

    // A local DB already exists on this device (from a previous install
    // or an earlier build). Check whether it's up to date with the
    // content shipped in THIS build, and refresh it if not — without
    // touching bookmarks/notes/highlights.
    final db = await openDatabase(dbPath);
    final lastApplied = await _getLastAppliedVersion();
    if (lastApplied < _currentContentVersion) {
      await _ensureSchema(db);
      await _refreshContentFromAsset(db);
      await _setLastAppliedVersion(_currentContentVersion);
    }
    return db;
  }

  static Future<void> _copyAssetDbTo(String destPath) async {
    final data = await rootBundle.load('assets/db/$_dbFileName');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await File(destPath).writeAsBytes(bytes, flush: true);
  }

  static Future<int> _getLastAppliedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kLastAppliedVersionPref) ?? 0;
  }

  static Future<void> _setLastAppliedVersion(int version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastAppliedVersionPref, version);
  }

  /// Recreates any table/column/FTS setup that might be missing from an
  /// older local DB (e.g. a device that installed a build from before
  /// 'notes'/'highlights' existed), so a version bump always converges
  /// to the same schema regardless of how old the local copy is.
  static Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY,
        type TEXT NOT NULL,
        ref_id INTEGER NOT NULL,
        note_text TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_ref ON notes(type, ref_id)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS highlights (
        id INTEGER PRIMARY KEY,
        type TEXT NOT NULL,
        ref_id INTEGER NOT NULL,
        color_hex TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_highlights_ref ON highlights(type, ref_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_verses_version ON bible_verses(version, book_num, chapter, verse)',
    );

    final hymnsColumns = await db.rawQuery('PRAGMA table_info(hymns)');
    final hasAudioUrl = hymnsColumns.any((c) => c['name'] == 'audio_url');
    if (!hasAudioUrl) {
      await db.execute('ALTER TABLE hymns ADD COLUMN audio_url TEXT');
    }

    // FTS5 virtual tables can't use "IF NOT EXISTS" reliably across all
    // SQLite builds the same way normal tables can, so check first.
    Future<bool> ftsTableExists(String name) async {
      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
        [name],
      );
      return rows.isNotEmpty;
    }

    if (!await ftsTableExists('bible_verses_fts')) {
      await db.execute(
        "CREATE VIRTUAL TABLE bible_verses_fts USING fts5(text, content='bible_verses', content_rowid='id', tokenize='unicode61')",
      );
      await db.execute(
        'INSERT INTO bible_verses_fts(rowid, text) SELECT id, text FROM bible_verses',
      );
    }
    if (!await ftsTableExists('hymns_fts')) {
      await db.execute(
        "CREATE VIRTUAL TABLE hymns_fts USING fts5(title, lyrics, content='hymns', content_rowid='id', tokenize='unicode61')",
      );
      await db.execute(
        'INSERT INTO hymns_fts(rowid, title, lyrics) SELECT id, title, lyrics FROM hymns',
      );
    }
    if (!await ftsTableExists('dictionary_fts')) {
      await db.execute(
        "CREATE VIRTUAL TABLE dictionary_fts USING fts5(term, definition, content='dictionary_entries', content_rowid='id', tokenize='unicode61')",
      );
      await db.execute(
        'INSERT INTO dictionary_fts(rowid, term, definition) SELECT id, term, definition FROM dictionary_entries',
      );
    }
  }

  /// Refreshes Bible/hymns/dictionary content (and their search indexes)
  /// from the freshly bundled asset DB, leaving bookmarks/notes/highlights
  /// on the device completely untouched.
  static Future<void> _refreshContentFromAsset(Database db) async {
    final tempDir = await getTemporaryDirectory();
    final tempAssetPath = join(tempDir.path, 'app_data_asset_ref.db');
    await _copyAssetDbTo(tempAssetPath);

    await db.execute("ATTACH DATABASE '$tempAssetPath' AS freshdb");
    try {
      await db.transaction((txn) async {
        for (final table in ['bible_verses', 'hymns', 'dictionary_entries']) {
          await txn.execute('DELETE FROM $table');
          await txn.execute('INSERT INTO $table SELECT * FROM freshdb.$table');
        }
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
      await db.execute('DETACH DATABASE freshdb');
      final tempFile = File(tempAssetPath);
      if (await tempFile.exists()) await tempFile.delete();
    }
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
