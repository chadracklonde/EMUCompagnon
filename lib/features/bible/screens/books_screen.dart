import 'package:flutter/material.dart';
import '../repository/bible_repository.dart';
import 'chapter_list_screen.dart';
import '../../concordance/screens/concordance_screen.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  static const _ancienTestament = 39;

  @override
  Widget build(BuildContext context) {
    final books = BibleRepository.books;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Concordance',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConcordanceScreen()),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: books.length + 2, // +2 for the two section headers
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _SectionHeader('Ancien Testament');
          }
          if (index == _ancienTestament + 1) {
            return const _SectionHeader('Nouveau Testament');
          }
          final bookIndex = index <= _ancienTestament ? index - 1 : index - 2;
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
