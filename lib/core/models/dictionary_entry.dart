import '../../shared/bible_book_abbreviations.dart';

class DictionaryEntry {
  final int id;
  final String term;
  final String definition;
  final List<String> relatedReferences;

  DictionaryEntry({
    required this.id,
    required this.term,
    required this.definition,
    required this.relatedReferences,
  });

  factory DictionaryEntry.fromMap(Map<String, dynamic> map) {
    final raw = map['related_verses'] as String?;
    return DictionaryEntry(
      id: map['id'] as int,
      term: map['term'] as String,
      definition: map['definition'] as String,
      relatedReferences: _parseRelatedVerses(raw),
    );
  }

  /// Splits a `related_verses` string like "Gn 4:18 ; 5:28" or
  /// "Genèse 22.13; Exode 29.15-18" on ';' into individual references.
  ///
  /// A citation style that lists several verses from the SAME book often
  /// states the book name only once (e.g. "Gn 4:18 ; 5:28" — the second
  /// half is Genèse 5:28, not a bookless reference). Splitting naively on
  /// ';' loses that shared book name for every fragment after the first,
  /// which made those chips unable to link anywhere. This carries the
  /// last-seen book token forward onto any fragment that doesn't start
  /// with its own.
  static List<String> _parseRelatedVerses(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final parts = raw.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty);
    String? lastBookToken;
    final result = <String>[];
    for (final part in parts) {
      final bookToken = extractLeadingBookToken(part);
      if (bookToken != null) {
        lastBookToken = bookToken;
        result.add(part);
      } else if (lastBookToken != null) {
        result.add('$lastBookToken $part');
      } else {
        result.add(part); // no book context available — kept as-is
      }
    }
    return result;
  }
}
