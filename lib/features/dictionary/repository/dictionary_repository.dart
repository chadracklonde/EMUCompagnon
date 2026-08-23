import '../../../core/database/db_helper.dart';
import '../../../core/models/dictionary_entry.dart';

class DictionaryRepository {
  Future<List<DictionaryEntry>> getAll() async {
    final db = await DbHelper.database;
    final rows = await db.query('dictionary_entries', orderBy: 'term ASC');
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

  String _sanitizeFtsQuery(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    final words = trimmed.split(RegExp(r'\s+'));
    return words.map((w) => '"${w.replaceAll('"', '')}"').join(' ');
  }
}
