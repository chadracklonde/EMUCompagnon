import '../../../core/database/db_helper.dart';
import '../../../core/models/dictionary_entry.dart';

class DictionaryRepository {
  Future<List<DictionaryEntry>> getAll() async {
    final db = await DbHelper.database;
    final rows = await db.query('dictionary_entries', orderBy: 'term ASC');
    return rows.map((r) => DictionaryEntry.fromMap(r)).toList();
  }

  /// All entry ids, cheap to fetch in full (small integers) and used by
  /// features like the daily quiz to pick a deterministic random sample
  /// without loading every definition into memory.
  Future<List<int>> getAllIds() async {
    final db = await DbHelper.database;
    final rows = await db.query('dictionary_entries', columns: ['id']);
    return rows.map((r) => r['id'] as int).toList();
  }

  Future<List<DictionaryEntry>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await DbHelper.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.query(
      'dictionary_entries',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return rows.map((r) => DictionaryEntry.fromMap(r)).toList();
  }

  Future<List<DictionaryEntry>> search(String query, {int limit = 100}) async {
    final db = await DbHelper.database;
    final sanitized = _sanitizeFtsQuery(query);
    if (sanitized.isEmpty) return [];
    final rows = await db.rawQuery('''
      SELECT dictionary_entries.* FROM dictionary_entries
      JOIN dictionary_fts ON dictionary_entries.id = dictionary_fts.rowid
      WHERE dictionary_fts MATCH ?
      ORDER BY dictionary_entries.term ASC
      LIMIT ?
    ''', [sanitized, limit]);
    return rows.map((r) => DictionaryEntry.fromMap(r)).toList();
  }

  /// See the detailed comment in BibleRepository._sanitizeFtsQuery: the
  /// trailing `*` turns each token into an FTS5 prefix query, which is
  /// required because the search UI runs live, on every keystroke.
  String _sanitizeFtsQuery(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    final words = trimmed
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll('"', ''))
        .where((w) => w.isNotEmpty);
    if (words.isEmpty) return '';
    return words.map((w) => '"$w"*').join(' ');
  }
}
