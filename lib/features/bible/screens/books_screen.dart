import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/verse.dart';
import '../../../core/models/bible_version.dart';
import '../../../core/settings/app_settings.dart';
import '../repository/bible_repository.dart';
import 'chapter_list_screen.dart';
import 'chapter_screen.dart';
import '../../concordance/screens/concordance_screen.dart';
import '../../search/screens/global_search_screen.dart';
import '../../../core/services/reading_history_service.dart';
import '../../reading_plan/screens/reading_plan_screen.dart';
import '../../../shared/widgets/version_picker.dart';

enum TestamentFilter { all, oldTestament, newTestament }

class BooksScreen extends StatefulWidget {
  final TestamentFilter filter;
  const BooksScreen({super.key, this.filter = TestamentFilter.all});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  static const _ancienTestament = 39;
  final _repo = BibleRepository();
  Verse? _verseOfTheDay;
  ({String book, int chapter})? _lastRead;
  String? _loadedForVersion;

  @override
  void initState() {
    super.initState();
    ReadingHistoryService.getLastBibleRead().then((r) {
      if (mounted) setState(() => _lastRead = r);
    });
  }

  void _loadVerseOfDay(String version) {
    if (_loadedForVersion == version) return;
    _loadedForVersion = version;
    _repo.getVerseOfTheDay(version: version).then((v) {
      if (mounted) setState(() => _verseOfTheDay = v);
    });
  }

  Future<void> _pickVersion(AppSettings settings) async {
    final chosen = await showVersionPicker(context, current: settings.bibleVersion);
    if (chosen != null) {
      await settings.setBibleVersion(chosen);
      _loadedForVersion = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final version = settings.bibleVersion;
    _loadVerseOfDay(version);
    final versionInfo = BibleVersions.byCode(version);
    final allBooks = BibleRepository.books;
    final isFiltered = widget.filter != TestamentFilter.all;

    final List<String> books = switch (widget.filter) {
      TestamentFilter.oldTestament => allBooks.sublist(0, _ancienTestament),
      TestamentFilter.newTestament => allBooks.sublist(_ancienTestament),
      TestamentFilter.all => allBooks,
    };

    final appBarTitle = switch (widget.filter) {
      TestamentFilter.oldTestament => 'Ancien Testament',
      TestamentFilter.newTestament => 'Nouveau Testament',
      TestamentFilter.all => 'Bible',
    };

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(appBarTitle),
            Text(
              versionInfo.name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: 'Version de la Bible',
            onPressed: () => _pickVersion(settings),
          ),
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'Plan de lecture',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReadingPlanScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.travel_explore),
            tooltip: 'Recherche globale (Bible, Cantiques, Dictionnaire)',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Concordance',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConcordanceScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isFiltered && _lastRead != null)
            _ResumeReadingCard(lastRead: _lastRead!, version: version),
          if (!isFiltered && _verseOfTheDay != null)
            _VerseOfTheDayCard(verse: _verseOfTheDay!, version: version),
          Expanded(
            child: ListView.builder(
              itemCount: isFiltered ? books.length : books.length + 2,
              itemBuilder: (context, index) {
                if (!isFiltered) {
                  if (index == 0) {
                    return const _SectionHeader('Ancien Testament');
                  }
                  if (index == _ancienTestament + 1) {
                    return const _SectionHeader('Nouveau Testament');
                  }
                }
                final book = isFiltered
                    ? books[index]
                    : books[index <= _ancienTestament ? index - 1 : index - 2];
                return ListTile(
                  title: Text(book),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChapterListScreen(book: book, version: version)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeReadingCard extends StatelessWidget {
  final ({String book, int chapter}) lastRead;
  final String version;
  const _ResumeReadingCard({required this.lastRead, required this.version});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChapterScreen(book: lastRead.book, chapter: lastRead.chapter, version: version),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.history, color: scheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reprendre la lecture — ${lastRead.book} ${lastRead.chapter}',
                    style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerseOfTheDayCard extends StatelessWidget {
  final Verse verse;
  final String version;
  const _VerseOfTheDayCard({required this.verse, required this.version});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChapterScreen(
                book: verse.book,
                chapter: verse.chapter,
                highlightVerse: verse.verse,
                version: version,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, size: 16, color: scheme.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      'VERSET DU JOUR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  verse.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  verse.reference,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
