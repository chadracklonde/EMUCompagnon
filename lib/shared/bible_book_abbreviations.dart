import '../features/bible/repository/bible_repository.dart';
import 'bible_reference_parser.dart';

/// Maps the French Bible-reference abbreviations used by common citation
/// styles ("Gn", "Hé", "1 Co"...) to the canonical book names used
/// throughout the app (see `BibleRepository.books`).
///
/// Only the 66-book Protestant canon that this app's Bible actually
/// contains is mapped — citations to deuterocanonical/apocryphal books
/// ("Tb" for Tobie, "1 M" for 1 Maccabées...) are intentionally left
/// unmapped since there is no corresponding content to link to.
const Map<String, String> bibleBookAbbreviations = {
  'Gn': 'Genèse',
  'Ex': 'Exode',
  'Lv': 'Lévitique',
  'Nb': 'Nombres',
  'Dt': 'Deutéronome',
  'Jos': 'Josué',
  'Jg': 'Juges',
  'Rt': 'Ruth',
  '1 S': '1 Samuel',
  '2 S': '2 Samuel',
  '1 R': '1 Rois',
  '2 R': '2 Rois',
  '1 Ch': '1 Chroniques',
  '2 Ch': '2 Chroniques',
  'Esd': 'Esdras',
  'Né': 'Néhémie',
  'Est': 'Esther',
  'Jb': 'Job',
  'Ps': 'Psaumes',
  'Pr': 'Proverbes',
  'Ec': 'Ecclésiaste',
  'Ct': 'Cantique',
  'És': 'Esaïe',
  'Es': 'Esaïe', // some citation styles drop the accent
  'Jr': 'Jérémie',
  'Lm': 'Lamentations',
  'Éz': 'Ezéchiel',
  'Ez': 'Ezéchiel',
  'Dn': 'Daniel',
  'Os': 'Osée',
  'Jl': 'Joël',
  'Am': 'Amos',
  'Ab': 'Abdias',
  'Jon': 'Jonas',
  'Mi': 'Michée',
  'Na': 'Nahum',
  'Ha': 'Habacuc',
  'So': 'Sophonie',
  'Ag': 'Aggée',
  'Za': 'Zacharie',
  'Ml': 'Malachie',
  'Mt': 'Matthieu',
  'Mc': 'Marc',
  'Lc': 'Luc',
  'Jn': 'Jean',
  'Ac': 'Actes',
  'Rm': 'Romains',
  '1 Co': '1 Corinthiens',
  '2 Co': '2 Corinthiens',
  'Ga': 'Galates',
  'Ep': 'Ephésiens',
  'Ph': 'Philippiens',
  'Col': 'Colossiens',
  '1 Th': '1 Thessaloniciens',
  '2 Th': '2 Thessaloniciens',
  '1 Tm': '1 Timothée',
  '2 Tm': '2 Timothée',
  'Tt': 'Tite',
  'Phm': 'Philémon',
  'Hé': 'Hébreux',
  'He': 'Hébreux',
  'Jc': 'Jacques',
  '1 P': '1 Pierre',
  '2 P': '2 Pierre',
  '1 Jn': '1 Jean',
  '2 Jn': '2 Jean',
  '3 Jn': '3 Jean',
  'Jude': 'Jude',
  'Jd': 'Jude',
  'Ap': 'Révélation',
  // Not abbreviations, but common alternate full names that don't match
  // this app's canonical book list (`BibleRepository.books` — see there
  // for why "Révélation" was chosen over "Apocalypse") — found while
  // testing this fix: several of the app's OWN earlier dictionary
  // entries used these names and had silently never linked anywhere.
  'Apocalypse': 'Révélation',
  'Psaume': 'Psaumes',
};

/// Recognizes a leading book token (full canonical name OR one of the
/// abbreviations above) at the start of [text], followed by whitespace
/// and a chapter number. Used specifically to parse the short, isolated
/// reference chips shown under a dictionary entry (e.g. "Gn 1-50",
/// "Hé 11:4"), which are NOT free-flowing prose — unlike
/// [BibleReferenceParser], which scans prose and therefore only matches
/// full book names to avoid false positives from short abbreviations.
final RegExp _chipLeadingBookPattern =
    RegExp(r'^((?:[123]\s)?[A-Za-zÀ-ÿ]+\.?)\s+\d');

/// If [part] starts with a recognizable book token, returns that token
/// exactly as written (so it can be remembered as the "current book" for
/// a later reference fragment in the same citation that omits it, e.g.
/// the "5:28" in "Gn 4:18 ; 5:28"). Returns null otherwise.
String? extractLeadingBookToken(String part) {
  final m = _chipLeadingBookPattern.firstMatch(part.trim());
  return m?.group(1);
}

/// Parses a single, self-contained reference chip such as "Gn 1-50",
/// "Hé 11:4" or "Genèse 22.13" into a navigable [BibleReferenceMatch].
/// Returns null if the leading book token isn't recognized (e.g. a
/// deuterocanonical book this app's Bible doesn't contain).
BibleReferenceMatch? parseChipReference(String text) {
  final trimmed = text.trim();
  final bookMatch = _chipLeadingBookPattern.firstMatch(trimmed);
  if (bookMatch == null) return null;
  final bookToken = bookMatch.group(1)!.replaceAll('.', '').trim();

  final rest = trimmed.substring(bookMatch.group(1)!.length).trim();
  final numberMatch = RegExp(r'^(\d{1,3})(?:[.:](\d{1,3}))?').firstMatch(rest);
  if (numberMatch == null) return null;
  final chapter = int.tryParse(numberMatch.group(1) ?? '');
  if (chapter == null) return null;
  final verseStr = numberMatch.group(2);

  final resolved = bibleBookAbbreviations[bookToken] ?? bookToken;
  // Guards against citations to books this app's Bible doesn't contain
  // (deuterocanonical/apocryphal references in the imported dictionary,
  // e.g. "Tb" for Tobie) — better to not link than to open a chapter
  // screen for a nonexistent book.
  if (!BibleRepository.books.contains(resolved)) return null;
  final book = resolved;

  return BibleReferenceMatch(
    start: 0,
    end: text.length,
    rawText: text,
    book: book,
    chapter: chapter,
    verse: verseStr != null ? int.tryParse(verseStr) : null,
  );
}
