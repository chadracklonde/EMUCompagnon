import '../../../core/database/db_helper.dart';
import '../../../core/models/hymn.dart';

class HymnsRepository {
  Future<List<Hymn>> getAll() async {
    final db = await DbHelper.database;
    final rows = await db.query('hymns', orderBy: 'CAST(number AS INTEGER) ASC, number ASC');
    return rows.map((r) => Hymn.fromMap(r)).toList();
  }

  Future<Hymn?> getByNumber(String number) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'hymns',
      where: 'number = ?',
      whereArgs: [number],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Hymn.fromMap(rows.first);
  }

  Future<List<Hymn>> search(String query, {int limit = 100}) async {
    final db = await DbHelper.database;
    final sanitized = _sanitizeFtsQuery(query);
    if (sanitized.isEmpty) return [];
    final rows = await db.rawQuery('''
      SELECT hymns.* FROM hymns
      JOIN hymns_fts ON hymns.id = hymns_fts.rowid
      WHERE hymns_fts MATCH ?
      ORDER BY CAST(hymns.number AS INTEGER) ASC
      LIMIT ?
    ''', [sanitized, limit]);
    return rows.map((r) => Hymn.fromMap(r)).toList();
  }

  String _sanitizeFtsQuery(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    final words = trimmed.split(RegExp(r'\s+'));
    return words.map((w) => '"${w.replaceAll('"', '')}"').join(' ');
  }
}
