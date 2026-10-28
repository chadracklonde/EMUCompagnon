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

  /// "125", "n° 125", "no 12", "#7", "123a" — a query that is just a hymn
  /// number (optionally with a twin-hymn letter suffix).
  static final RegExp _numberQuery = RegExp(
    r'^(?:n[°ºo]?\.?\s*|num[ée]ro\s*|#\s*)?(\d{1,4}[a-zA-Z]?)$',
    caseSensitive: false,
  );

  /// Searches hymns the way a singer actually looks for them:
  ///
  /// * A query that is a hymn number returns THAT hymn (plus its twin
  ///   "123a"/"123b" variants when the plain number doesn't exist) — not
  ///   every number that merely starts with those digits. The earlier
  ///   prefix match ("12" → 12, 120, 121 … 129, 12x…) forced users to
  ///   scroll through a run of unrelated hymns to find the one they typed.
  /// * Any other query is a text search where TITLE matches come first
  ///   (exact title, then titles starting with the query, then the rest),
  ///   and only then hymns whose LYRICS contain the words. Searching title
  ///   and lyrics together and sorting by number buried the hymn the user
  ///   named under dozens of hymns that merely mention the word
  ///   ("grand dieu" matched 52 hymns, only 2 of them by title).
  Future<List<Hymn>> search(String query, {int limit = 100}) async {
    final db = await DbHelper.database;
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final numberMatch = _numberQuery.firstMatch(trimmed);
    if (numberMatch != null) {
      final number = numberMatch.group(1)!.toLowerCase();
      final seen = <int>{};
      final results = <Hymn>[];
      final exact = await db.query(
        'hymns',
        where: 'LOWER(number) = ?',
        whereArgs: [number],
      );
      for (final r in exact) {
        final h = Hymn.fromMap(r);
        if (seen.add(h.id)) results.add(h);
      }
      if (results.isEmpty && RegExp(r'^\d+$').hasMatch(number)) {
        // Digits only (so safe inside a GLOB pattern): twin hymns "123a", "123b".
        final twins = await db.query(
          'hymns',
          where: 'number GLOB ?',
          whereArgs: ['$number[a-zA-Z]'],
          orderBy: 'number ASC',
        );
        for (final r in twins) {
          final h = Hymn.fromMap(r);
          if (seen.add(h.id)) results.add(h);
        }
      }
      return results;
    }

    final tokens = _tokens(trimmed);
    if (tokens.isEmpty) return [];
    final ftsTokens = tokens.map((w) => '"$w"*').join(' ');

    // 1) Title matches, ranked.
    final titleRows = await db.rawQuery(
      '''
      SELECT hymns.* FROM hymns
      JOIN hymns_fts ON hymns.id = hymns_fts.rowid
      WHERE hymns_fts MATCH ?
    ''',
      ['title : ($ftsTokens)'],
    );
    final titleHymns = titleRows.map((r) => Hymn.fromMap(r)).toList();
    final normQuery = _normalize(trimmed);
    int rank(Hymn h) {
      final t = _normalize(h.title);
      if (t == normQuery) return 0;
      if (t.startsWith(normQuery)) return 1;
      if (t.contains(normQuery)) return 2;
      return 3;
    }

    titleHymns.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : _compareNumbers(a.number, b.number);
    });

    final seen = <int>{};
    final results = <Hymn>[];
    for (final h in titleHymns) {
      if (seen.add(h.id)) results.add(h);
    }

    // 2) Then hymns that only match in the lyrics.
    if (results.length < limit) {
      final lyricRows = await db.rawQuery(
        '''
        SELECT hymns.* FROM hymns
        JOIN hymns_fts ON hymns.id = hymns_fts.rowid
        WHERE hymns_fts MATCH ?
        LIMIT ?
      ''',
        [ftsTokens, limit * 3],
      );
      final lyricHymns = lyricRows.map((r) => Hymn.fromMap(r)).toList()
        ..sort((a, b) => _compareNumbers(a.number, b.number));
      for (final h in lyricHymns) {
        if (seen.add(h.id)) results.add(h);
      }
    }

    return results.length > limit ? results.sublist(0, limit) : results;
  }

  /// Orders hymn numbers numerically, then by suffix: 9 < 10 < 123a < 123b.
  static int _compareNumbers(String a, String b) {
    final na = int.tryParse(RegExp(r'^\d+').stringMatch(a) ?? '') ?? 1 << 30;
    final nb = int.tryParse(RegExp(r'^\d+').stringMatch(b) ?? '') ?? 1 << 30;
    return na != nb ? na.compareTo(nb) : a.compareTo(b);
  }

  /// Lowercases and strips French accents/punctuation so "Bénissons",
  /// "benissons" and "BÉNISSONS !" compare equal.
  static String _normalize(String input) {
    const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœæ';
    const to = 'aaaaaaceeeeiiiinooooouuuuyyoa';
    final buf = StringBuffer();
    for (final ch in input.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    return buf
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  /// Splits the query into FTS-safe words (quotes removed).
  static List<String> _tokens(String input) => input
      .split(RegExp(r'\s+'))
      .map((w) => w.replaceAll('"', ''))
      .where((w) => w.isNotEmpty)
      .toList();
}
