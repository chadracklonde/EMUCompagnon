import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'platform/db_platform.dart' as platform;

/// Handles opening the pre-populated SQLite database bundled as an asset.
///
/// This file is deliberately platform-agnostic: it never imports dart:io
/// or any web-only package directly. The only two things that genuinely
/// need different code per platform — which SQLite engine to use, and
/// what a "database path" even means — live behind platform/db_platform.dart,
/// which picks the right implementation at COMPILE time so the web build
/// never has to resolve a dart:io import at all. Everything else here goes
/// through the universal `databaseFactory`/`Database` API, which works
/// identically on mobile, desktop, and web once the right engine is set.
///
/// IMPORTANT: the local copy on a device/browser is only ever written
/// once, the first time the app runs — after that, we just open whatever
/// already exists. If the bundled asset DB is later updated (new content,
/// fixed search index...), a device that already installed an earlier
/// build would silently keep using its old, stale local copy forever
/// without the version check below. [_currentContentVersion] fixes this:
/// bump it whenever assets/db/app_data.db changes in a way that needs to
/// reach already-installed devices.
class DbHelper {
  static Database? _db;
  static const _dbFileName = 'app_data.db';

  /// Bump this whenever assets/db/app_data.db is regenerated with new or
  /// fixed content/schema that already-installed devices need to receive.
  static const int _currentContentVersion = 2;
  static const _kLastAppliedVersionPref = 'db.lastAppliedContentVersion';

  static bool _factoryInitialized = false;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    if (!_factoryInitialized) {
      await platform.initializeDatabaseFactory();
      _factoryInitialized = true;
    }

    final dbPath = await platform.getDatabasePath(_dbFileName);
    final exists = await databaseFactory.databaseExists(dbPath);

    if (!exists) {
      final bytes = await _loadAssetBytes();
      await databaseFactory.writeDatabaseBytes(dbPath, bytes);
      await _setLastAppliedVersion(_currentContentVersion);
      return databaseFactory.openDatabase(dbPath);
    }

    // A local DB already exists (previous install, or an earlier build).
    // Check whether it's up to date with THIS build's content, and
    // refresh it if not.
    var db = await databaseFactory.openDatabase(dbPath);
    final lastApplied = await _getLastAppliedVersion();
    if (lastApplied < _currentContentVersion) {
      if (kIsWeb) {
        // On the web, bookmarks/notes/highlights never live in this
        // local database (they go to Supabase instead — see Phase 2/3),
        // so there is no personal data to protect here: a full wipe and
        // reseed is simple, safe, and always converges to a correct,
        // fully up-to-date schema.
        await db.close();
        final bytes = await _loadAssetBytes();
        await databaseFactory.writeDatabaseBytes(dbPath, bytes);
        db = await databaseFactory.openDatabase(dbPath);
      } else {
        // Mobile/desktop: bookmarks/notes/highlights DO live in this same
        // file, so refresh content tables + search indexes surgically,
        // preserving personal data untouched.
        await _ensureSchema(db);
        await _refreshContentFromAsset(db);
      }
      await _setLastAppliedVersion(_currentContentVersion);
    }
    return db;
  }

  static Future<Uint8List> _loadAssetBytes() async {
    final data = await rootBundle.load('assets/db/$_dbFileName');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
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
  /// 'notes'/'highlights' existed), so a version bump always converges to
  /// the same schema regardless of how old the local copy is.
  /// (Mobile/desktop only — see the web branch in [_initDb].)
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
  /// on the device completely untouched. (Mobile/desktop only.)
  static Future<void> _refreshContentFromAsset(Database db) async {
    final tempPath = await platform.getDatabasePath('app_data_asset_ref.db');
    final bytes = await _loadAssetBytes();
    await databaseFactory.writeDatabaseBytes(tempPath, bytes);

    await db.execute("ATTACH DATABASE '$tempPath' AS freshdb");
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
      await databaseFactory.deleteDatabase(tempPath);
    }
  }

  /// Useful during development if the bundled DB is updated and you want
  /// to force a fresh copy on next launch.
  static Future<void> resetDatabase() async {
    if (!_factoryInitialized) {
      await platform.initializeDatabaseFactory();
      _factoryInitialized = true;
    }
    final dbPath = await platform.getDatabasePath(_dbFileName);
    await databaseFactory.deleteDatabase(dbPath);
    _db = null;
  }

  /// Merges a freshly downloaded content database (Bible/hymns/dictionary)
  /// into the live one, WITHOUT touching the user's personal data
  /// (bookmarks, notes, highlights) — those tables are never referenced
  /// here, so they survive untouched. Used by the content-update feature
  /// (mobile/desktop only — not offered on web, see ContentUpdateScreen).
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
