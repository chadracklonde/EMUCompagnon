import '../../../core/models/verse.dart';
import '../../../core/models/hymn.dart';
import '../../../core/models/dictionary_entry.dart';
import '../../bible/repository/bible_repository.dart';
import '../../hymns/repository/hymns_repository.dart';
import '../../dictionary/repository/dictionary_repository.dart';
import 'content_search.dart';

class GlobalSearchResults {
  final List<Verse> verses;
  final List<Hymn> hymns;
  final List<DictionaryEntry> dictionaryEntries;

  /// Liturgy pages and "Prières et textes".
  final List<ContentHit> texts;

  GlobalSearchResults({
    required this.verses,
    required this.hymns,
    required this.dictionaryEntries,
    this.texts = const [],
  });

  bool get isEmpty =>
      verses.isEmpty && hymns.isEmpty && dictionaryEntries.isEmpty && texts.isEmpty;

  int get totalCount => verses.length + hymns.length + dictionaryEntries.length + texts.length;
}

/// Searches the content sources (Bible, hymns, dictionary, and the liturgy
/// and church texts written into the app) in
/// parallel and returns a capped set of results from each, for a unified
/// "search everything" experience.
class GlobalSearchRepository {
  final _bibleRepo = BibleRepository();
  final _hymnsRepo = HymnsRepository();
  final _dictionaryRepo = DictionaryRepository();

  Future<GlobalSearchResults> search(String query, {int limitPerSource = 20}) async {
    if (query.trim().isEmpty) {
      return GlobalSearchResults(verses: [], hymns: [], dictionaryEntries: []);
    }
    final results = await Future.wait([
      _bibleRepo.search(query, limit: limitPerSource),
      _hymnsRepo.search(query, limit: limitPerSource),
      _dictionaryRepo.search(query, limit: limitPerSource),
    ]);
    return GlobalSearchResults(
      verses: results[0] as List<Verse>,
      hymns: results[1] as List<Hymn>,
      dictionaryEntries: results[2] as List<DictionaryEntry>,
      texts: ContentSearch.search(query, limit: limitPerSource),
    );
  }
}
