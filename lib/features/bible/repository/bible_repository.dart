import '../../../core/database/db_helper.dart';
import '../../../core/models/verse.dart';

class BibleRepository {
  /// Canonical 66-book order, used for navigation and sorting.
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

  Future<int> chapterCount(String book) async {
    final db = await DbHelper.database;
    final rows = await db.rawQuery(
      'SELECT MAX(chapter) as maxChapter FROM bible_verses WHERE book = ?',
      [book],
    );
    return (rows.first['maxChapter'] as int?) ?? 0;
  }

  Future<List<Verse>> getChapter(String book, int chapter) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'bible_verses',
      where: 'book = ? AND chapter = ?',
      whereArgs: [book, chapter],
      orderBy: 'verse ASC',
    );
    return rows.map((r) => Verse.fromMap(r)).toList();
  }

  Future<Verse?> getVerse(String book, int chapter, int verse) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'bible_verses',
      where: 'book = ? AND chapter = ? AND verse = ?',
      whereArgs: [book, chapter, verse],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Verse.fromMap(rows.first);
  }

  /// Full-text concordance search across the whole Bible via FTS5.
  Future<List<Verse>> search(String query, {int limit = 100}) async {
    final db = await DbHelper.database;
    final sanitized = _sanitizeFtsQuery(query);
    if (sanitized.isEmpty) return [];
    final rows = await db.rawQuery('''
      SELECT bible_verses.* FROM bible_verses
      JOIN bible_verses_fts ON bible_verses.id = bible_verses_fts.rowid
      WHERE bible_verses_fts MATCH ?
      ORDER BY bible_verses.book_num, bible_verses.chapter, bible_verses.verse
      LIMIT ?
    ''', [sanitized, limit]);
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
