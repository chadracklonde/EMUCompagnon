import 'package:flutter/material.dart';
import '../../../core/models/verse.dart';
import '../repository/bible_repository.dart';
import 'chapter_list_screen.dart';
import 'chapter_screen.dart';
import '../../concordance/screens/concordance_screen.dart';
import '../../search/screens/global_search_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  static const _ancienTestament = 39;
  final _repo = BibleRepository();
  Verse? _verseOfTheDay;

  @override
  void initState() {
    super.initState();
    _repo.getVerseOfTheDay().then((v) {
      if (mounted) setState(() => _verseOfTheDay = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final books = BibleRepository.books;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible'),
        actions: [
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
          if (_verseOfTheDay != null) _VerseOfTheDayCard(verse: _verseOfTheDay!),
          Expanded(
            child: ListView.builder(
              itemCount: books.length + 2, // +2 for the two section headers
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const _SectionHeader('Ancien Testament');
                }
                if (index == _ancienTestament + 1) {
                  return const _SectionHeader('Nouveau Testament');
                }
                final bookIndex =
                    index <= _ancienTestament ? index - 1 : index - 2;
                final book = books[bookIndex];
                return ListTile(
                  title: Text(book),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChapterListScreen(book: book)),
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

class _VerseOfTheDayCard extends StatelessWidget {
  final Verse verse;
  const _VerseOfTheDayCard({required this.verse});

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
