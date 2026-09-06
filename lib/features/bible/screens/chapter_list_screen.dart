import 'package:flutter/material.dart';
import '../repository/bible_repository.dart';
import 'chapter_screen.dart';
import '../../../shared/responsive/responsive.dart';

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
  // Only meaningful in the wide (master-detail) layout.
  int? _selectedChapter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final count = await _repo.chapterCount(widget.book, version: widget.version);
    if (mounted) setState(() => _chapterCount = count);
  }

  void _openChapter(int chapter, bool isWide) {
    if (isWide) {
      setState(() => _selectedChapter = chapter);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChapterScreen(
            book: widget.book,
            chapter: chapter,
            version: widget.version,
          ),
        ),
      );
    }
  }

  Widget _buildGrid(bool isWide) {
    return _chapterCount == null
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 4 : 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _chapterCount,
            itemBuilder: (context, index) {
              final chapter = index + 1;
              return _ChapterTile(
                chapter: chapter,
                selected: isWide && _selectedChapter == chapter,
                onTap: () => _openChapter(chapter, isWide),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.book)),
      body: !isWide
          ? _buildGrid(false)
          : Row(
              children: [
                SizedBox(width: 320, child: _buildGrid(true)),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _selectedChapter == null
                      ? Center(
                          child: Text(
                            'Sélectionnez un chapitre',
                            style: TextStyle(color: Theme.of(context).colorScheme.outline),
                          ),
                        )
                      : ChapterScreen(
                          book: widget.book,
                          chapter: _selectedChapter!,
                          version: widget.version,
                          showBackButton: false,
                        ),
                ),
              ],
            ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final int chapter;
  final bool selected;
  final VoidCallback onTap;
  const _ChapterTile({required this.chapter, required this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Center(
          child: Text(
            '$chapter',
            style: TextStyle(fontSize: 16, color: selected ? scheme.onPrimary : null),
          ),
        ),
      ),
    );
  }
}
