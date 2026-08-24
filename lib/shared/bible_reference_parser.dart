import '../features/bible/repository/bible_repository.dart';

class BibleReferenceMatch {
  final int start;
  final int end;
  final String rawText;
  final String book;
  final int chapter;
  final int? verse;

  BibleReferenceMatch({
    required this.start,
    required this.end,
    required this.rawText,
    required this.book,
    required this.chapter,
    this.verse,
  });
}

/// Finds Bible references such as "Genèse 12", "Jean 3.16", "Jean 3:16" or
/// "Matthieu 2.1-12" inside free text, so they can be rendered as tappable
/// links. Matching is book-name based (against the canonical 66-book list)
/// rather than free-form NLP, to avoid false positives.
class BibleReferenceParser {
  static final RegExp _pattern = _buildPattern();

  static RegExp _buildPattern() {
    // Longest names first so e.g. "1 Corinthiens" isn't partially matched
    // by a shorter, unrelated prefix.
    final sorted = [...BibleRepository.books]
      ..sort((a, b) => b.length.compareTo(a.length));
    final alternation = sorted.map(RegExp.escape).join('|');
    // Group 1: book name. Group 2: chapter. Group 3: verse (optional).
    // A trailing "-NN" verse range is matched but only the start verse is
    // kept, since navigation targets a single verse.
    return RegExp(
      r'(' + alternation + r')\s+(\d{1,3})(?:[.:](\d{1,3})(?:-\d{1,3})?)?',
    );
  }

  static List<BibleReferenceMatch> findAll(String text) {
    final matches = <BibleReferenceMatch>[];
    for (final m in _pattern.allMatches(text)) {
      final book = m.group(1)!;
      final chapter = int.tryParse(m.group(2) ?? '');
      if (chapter == null) continue;
      final verseStr = m.group(3);
      matches.add(BibleReferenceMatch(
        start: m.start,
        end: m.end,
        rawText: m.group(0)!,
        book: book,
        chapter: chapter,
        verse: verseStr != null ? int.tryParse(verseStr) : null,
      ));
    }
    return matches;
  }
}
