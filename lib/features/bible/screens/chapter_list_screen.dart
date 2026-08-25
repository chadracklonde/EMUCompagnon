import 'package:flutter/material.dart';
import '../repository/bible_repository.dart';
import 'chapter_screen.dart';

class ChapterListScreen extends StatefulWidget {
  final String book;
  final String version;
  const ChapterListScreen({super.key, required this.book, this.version = 'LSG1910'});

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  final _repo = BibleRepository();
  int? _chapterCount;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final count = await _repo.chapterCount(widget.book, version: widget.version);
    if (mounted) setState(() => _chapterCount = count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book)),
      body: _chapterCount == null
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _chapterCount,
              itemBuilder: (context, index) {
                final chapter = index + 1;
                return _ChapterTile(
                  chapter: chapter,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChapterScreen(
                        book: widget.book,
                        chapter: chapter,
                        version: widget.version,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final int chapter;
  final VoidCallback onTap;
  const _ChapterTile({required this.chapter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Center(
          child: Text('$chapter', style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
