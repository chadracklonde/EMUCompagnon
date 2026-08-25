import 'package:flutter/material.dart';
import '../../bible/repository/bible_repository.dart';
import '../../bible/screens/chapter_list_screen.dart';
import '../theme/home_colors.dart';

enum Testament { ancien, nouveau }

class TestamentBooksScreen extends StatelessWidget {
  final Testament testament;
  const TestamentBooksScreen({super.key, required this.testament});

  static const _ancienCount = 39;

  @override
  Widget build(BuildContext context) {
    final books = BibleRepository.books;
    final list = testament == Testament.ancien
        ? books.sublist(0, _ancienCount)
        : books.sublist(_ancienCount);
    final title = testament == Testament.ancien ? 'Ancien Testament' : 'Nouveau Testament';

    return Scaffold(
      backgroundColor: HomeColors.cream,
      appBar: AppBar(
        backgroundColor: HomeColors.navy,
        foregroundColor: HomeColors.cream,
        title: Text(title),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final book = list[index];
          return Material(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChapterListScreen(book: book)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        book,
                        style: const TextStyle(fontSize: 16, color: HomeColors.navy),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: HomeColors.gold),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
