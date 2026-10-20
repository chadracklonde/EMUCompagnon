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

  /// Searches both by hymn number ("125", "123a"...) and by text
  /// (title/lyrics), merging the two so a search bar doubles as a
  /// hymn-number lookup.
  ///
  /// Number matches are fetched first and take priority in the result
  /// order: typing "125" is almost always someone looking for hymn
  /// n°125, and "125" would never be found by the text search below —
  /// it's a number, not a word that appears in any title or lyrics.
  Future<List<Hymn>> search(String query, {int limit = 100}) async {
    final db = await DbHelper.database;
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final seenIds = <int>{};
    final results = <Hymn>[];

    // A query starting with a digit is treated as a hymn-number lookup
    // (prefix match, so "12" finds 12, 120, 121, 123a, 123b... while the
    // user is still typing). Hymn numbers can carry a letter suffix for
    // twin hymns (e.g. "123a"/"123b"), hence the TEXT column + LIKE
    // rather than a numeric comparison.
    if (RegExp(r'^\d').hasMatch(trimmed)) {
      final numberRows = await db.query(
        'hymns',
        where: 'number LIKE ?',
        whereArgs: ['$trimmed%'],
        orderBy: 'CAST(number AS INTEGER) ASC, number ASC',
        limit: limit,
      );
      for (final r in numberRows) {
        final hymn = Hymn.fromMap(r);
        if (seenIds.add(hymn.id)) results.add(hymn);
      }
    }

    if (results.length < limit) {
      final sanitized = _sanitizeFtsQuery(trimmed);
      if (sanitized.isNotEmpty) {
        final rows = await db.rawQuery('''
          SELECT hymns.* FROM hymns
          JOIN hymns_fts ON hymns.id = hymns_fts.rowid
          WHERE hymns_fts MATCH ?
          ORDER BY CAST(hymns.number AS INTEGER) ASC
          LIMIT ?
        ''', [sanitized, limit]);
        for (final r in rows) {
          final hymn = Hymn.fromMap(r);
          if (seenIds.add(hymn.id)) results.add(hymn);
        }
      }
    }

    return results.length > limit ? results.sublist(0, limit) : results;
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
