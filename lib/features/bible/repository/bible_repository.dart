import '../../../core/database/db_helper.dart';
import '../../../core/models/verse.dart';

class BibleRepository {
  /// Canonical 66-book order, used for navigation and sorting. Shared by
  /// every Bible version — versification (which book/chapter goes where)
  /// is assumed consistent across translations of the same 66-book canon.
  static const List<String> books = [
    'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
    'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel', '1 Rois', '2 Rois',
    '1 Chroniques', '2 Chroniques', 'Esdras', 'Néhémie', 'Esther',
    'Job', 'Psaumes', 'Proverbes', 'Ecclésiaste', 'Cantique',
    'Esaïe', 'Jérémie', 'Lamentations', 'Ezéchiel', 'Daniel',
    'Osée', 'Joël', 'Amos', 'Abdias', 'Jonas', 'Michée', 'Nahum',
    'Habacuc', 'Sophonie', 'Aggée', 'Zacharie', 'Malachie',
    'Matthieu', 'Marc', 'Luc', 'Jean', 'Actes',
    'Romains', '1 Corinthiens', '2 Corinthiens', 'Galates', 'Ephésiens',
    'Philippiens', 'Colossiens', '1 Thessaloniciens', '2 Thessaloniciens',
    '1 Timothée', '2 Timothée', 'Tite', 'Philémon', 'Hébreux',
    'Jacques', '1 Pierre', '2 Pierre', '1 Jean', '2 Jean', '3 Jean',
    'Jude', 'Révélation',
  ];

  static const _defaultVersion = 'LSG1910';

  Future<int> chapterCount(String book, {String version = _defaultVersion}) async {
    final db = await DbHelper.database;
    final rows = await db.rawQuery(
      'SELECT MAX(chapter) as maxChapter FROM bible_verses WHERE book = ? AND version = ?',
      [book, version],
    );
    return (rows.first['maxChapter'] as int?) ?? 0;
  }

  /// Picks a deterministic "verse of the day" — same verse all day, changes
  /// daily, cycles through the whole Bible over the course of a few years.
  Future<Verse?> getVerseOfTheDay({String version = _defaultVersion}) async {
    final db = await DbHelper.database;
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as c FROM bible_verses WHERE version = ?',
      [version],
    );
    final total = (countResult.first['c'] as int?) ?? 0;
    if (total == 0) return null;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final offset = dayOfYear % total;
    final rows = await db.query(
      'bible_verses',
      where: 'version = ?',
      whereArgs: [version],
      orderBy: 'id ASC',
      limit: 1,
      offset: offset,
    );
    if (rows.isEmpty) return null;
    return Verse.fromMap(rows.first);
  }

  Future<List<Verse>> getChapter(
    String book,
    int chapter, {
    String version = _defaultVersion,
  }) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'bible_verses',
      where: 'book = ? AND chapter = ? AND version = ?',
      whereArgs: [book, chapter, version],
      orderBy: 'verse ASC',
    );
    return rows.map((r) => Verse.fromMap(r)).toList();
  }

  Future<Verse?> getVerse(
    String book,
    int chapter,
    int verse, {
    String version = _defaultVersion,
  }) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'bible_verses',
      where: 'book = ? AND chapter = ? AND verse = ? AND version = ?',
      whereArgs: [book, chapter, verse, version],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Verse.fromMap(rows.first);
  }

  /// Full-text concordance search, scoped to a single version so results
  /// from two languages never mix together.
  Future<List<Verse>> search(
    String query, {
    int limit = 100,
    String version = _defaultVersion,
  }) async {
    final db = await DbHelper.database;
    final sanitized = _sanitizeFtsQuery(query);
    if (sanitized.isEmpty) return [];
    final rows = await db.rawQuery('''
      SELECT bible_verses.* FROM bible_verses
      JOIN bible_verses_fts ON bible_verses.id = bible_verses_fts.rowid
      WHERE bible_verses_fts MATCH ? AND bible_verses.version = ?
      ORDER BY bible_verses.book_num, bible_verses.chapter, bible_verses.verse
      LIMIT ?
    ''', [sanitized, version, limit]);
    return rows.map((r) => Verse.fromMap(r)).toList();
  }

  /// FTS5 special characters must be escaped/quoted for safe user input.
  String _sanitizeFtsQuery(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    // Wrap each word in double quotes to treat as literal tokens, avoiding
    // FTS5 syntax errors from punctuation the user might type.
    final words = trimmed.split(RegExp(r'\s+'));
    return words.map((w) => '"${w.replaceAll('"', '')}"').join(' ');
  }
}
