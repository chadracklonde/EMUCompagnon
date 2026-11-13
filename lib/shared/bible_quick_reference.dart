import '../features/bible/repository/bible_repository.dart';
import 'bible_book_abbreviations.dart';
import 'bible_book_names.dart';
import 'bible_reference_parser.dart';

/// Understands a Bible reference as a person types it in a search box:
/// "Jean 3.16", "jean 3 16", "Jn 3:16", "ps 23", "1 cor 13", "gen 1".
///
/// More forgiving than [BibleReferenceParser] (which finds references
/// inside prose and so must be strict): case and accents are ignored,
/// the verse separator can be a dot, colon, comma or space, and a book
/// may be given by its usual abbreviation or by the start of its name
/// when that start points to a single book.
class BibleQuickReference {
  static final RegExp _shape = RegExp(
    r'^\s*((?:[123]\s*)?[a-z]+)\.?\s*(\d{1,3})(?:\s*[.:,\s]\s*(\d{1,3}))?\s*$',
  );

  static const _accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'œ': 'oe',
  };

  /// Lower-case, no accents, no inner spaces ("1 Corinthiens" → "1corinthiens").
  static String _fold(String text) {
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      if (char == ' ') continue;
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }

  /// Other names people use for a book of this Bible.
  static const _aliases = {
    'Apocalypse': 'Révélation',
    'Cantique des cantiques': 'Cantique',
    'Actes des apôtres': 'Actes',
  };

  static final Map<String, String> _byName = {
    for (final book in BibleRepository.books) _fold(book): book,
    // Noms swahilis (« Yohana 3:16 », « Zaburi 23 »).
    for (var i = 0; i < BibleBookNames.sw.length; i++)
      _fold(BibleBookNames.sw[i]): BibleRepository.books[i],
    for (final alias in _aliases.entries)
      if (BibleRepository.books.contains(alias.value)) _fold(alias.key): alias.value,
  };

  static final Map<String, String> _byAbbreviation = {
    for (final entry in bibleBookAbbreviations.entries)
      if (BibleRepository.books.contains(entry.value)) _fold(entry.key): entry.value,
  };

  static String? _resolveBook(String token) {
    final key = _fold(token);
    final exact = _byName[key] ?? _byAbbreviation[key];
    if (exact != null) return exact;
    if (key.replaceAll(RegExp(r'[123]'), '').length < 2) return null;
    // Several names may lead to the same book ("Cantique", "Cantique des
    // cantiques"): what matters is that only one book is possible.
    final candidates =
        _byName.entries.where((e) => e.key.startsWith(key)).map((e) => e.value).toSet();
    return candidates.length == 1 ? candidates.single : null;
  }

  /// Returns the reference [query] points to, or null when it is not one
  /// (an ordinary search word, an unknown or ambiguous book…).
  static BibleReferenceMatch? parse(String query) {
    final lowered = query.toLowerCase().split('').map((c) => _accents[c] ?? c).join();
    final match = _shape.firstMatch(lowered);
    if (match == null) return null;
    final book = _resolveBook(match.group(1)!);
    final chapter = int.tryParse(match.group(2)!);
    if (book == null || chapter == null || chapter < 1) return null;
    final verse = match.group(3) == null ? null : int.tryParse(match.group(3)!);
    return BibleReferenceMatch(
      start: 0,
      end: query.length,
      rawText: query,
      book: book,
      chapter: chapter,
      verse: verse == null || verse < 1 ? null : verse,
    );
  }
}
