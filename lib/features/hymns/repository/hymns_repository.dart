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

    // Text search, done in memory over the ~450 hymns instead of through
    // SQLite FTS5: FTS5 is not available in the system SQLite of every
    // Android version, and when it is missing the query throws and NO
    // title is ever found. Accent- and case-insensitive, prefix-friendly
    // ("benis" finds "Bénissons"), every typed word must match.
    final tokens = _normalize(trimmed).split(' ').where((w) => w.isNotEmpty).toList();
    if (tokens.isEmpty) return [];
    final index = await _loadIndex();
    final normQuery = tokens.join(' ');

    bool matchesAll(String text) => tokens.every(
          (t) => text.startsWith(t) || text.contains(' $t'),
        );

    final titleHits = <(_IndexedHymn, int)>[];
    final lyricHits = <_IndexedHymn>[];
    for (final e in index) {
      if (matchesAll(e.title)) {
        final int rank;
        if (e.title == normQuery) {
          rank = 0;
        } else if (e.title.startsWith(normQuery)) {
          rank = 1;
        } else if (e.title.contains(normQuery)) {
          rank = 2;
        } else {
          rank = 3;
        }
        titleHits.add((e, rank));
      } else if (matchesAll(e.lyrics)) {
        lyricHits.add(e);
      }
    }
    titleHits.sort((a, b) {
      final byRank = a.$2.compareTo(b.$2);
      return byRank != 0 ? byRank : _compareNumbers(a.$1.hymn.number, b.$1.hymn.number);
    });
    lyricHits.sort((a, b) => _compareNumbers(a.hymn.number, b.hymn.number));

    final results = <Hymn>[
      for (final h in titleHits) h.$1.hymn,
      for (final h in lyricHits) h.hymn,
    ];
    return results.length > limit ? results.sublist(0, limit) : results;
  }

  static List<_IndexedHymn>? _indexCache;

  Future<List<_IndexedHymn>> _loadIndex() async {
    final cached = _indexCache;
    if (cached != null) return cached;
    final all = await getAll();
    return _indexCache = [
      for (final h in all)
        _IndexedHymn(h, _normalize(h.title), _normalize(h.lyrics)),
    ];
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
    const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
    const to = 'aaaaaaceeeeiiiinooooouuuuyy';
    final buf = StringBuffer();
    for (final ch in input
        .toLowerCase()
        .replaceAll('œ', 'oe')
        .replaceAll('æ', 'ae')
        .split('')) {
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    return buf
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }
}

class _IndexedHymn {
  final Hymn hymn;
  final String title;
  final String lyrics;
  _IndexedHymn(this.hymn, this.title, this.lyrics);
}
