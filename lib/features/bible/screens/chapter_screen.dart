import 'package:flutter/material.dart';
import '../../../core/models/verse.dart';
import '../../../core/models/bookmark.dart';
import '../repository/bible_repository.dart';
import '../../favorites/repository/bookmark_repository.dart';

class ChapterScreen extends StatefulWidget {
  final String book;
  final int chapter;
  const ChapterScreen({super.key, required this.book, required this.chapter});

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  final _repo = BibleRepository();
  final _bookmarkRepo = BookmarkRepository();
  List<Verse> _verses = [];
  Set<int> _bookmarkedVerseIds = {};
  bool _loading = true;
  late int _chapter;

  @override
  void initState() {
    super.initState();
    _chapter = widget.chapter;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final verses = await _repo.getChapter(widget.book, _chapter);
    final bookmarks = await _bookmarkRepo.listByType(BookmarkType.verse);
    final bookmarkedIds = bookmarks.map((b) => b.refId).toSet();
    if (mounted) {
      setState(() {
        _verses = verses;
        _bookmarkedVerseIds = verses
            .where((v) => bookmarkedIds.contains(v.id))
            .map((v) => v.id)
            .toSet();
        _loading = false;
      });
    }
  }

  Future<void> _toggleBookmark(Verse v) async {
    final nowBookmarked = await _bookmarkRepo.toggle(
      BookmarkType.verse,
      v.id,
      note: v.reference,
    );
    setState(() {
      if (nowBookmarked) {
        _bookmarkedVerseIds.add(v.id);
      } else {
        _bookmarkedVerseIds.remove(v.id);
      }
    });
  }

  void _goToChapter(int delta) async {
    final target = _chapter + delta;
    if (target < 1) return;
    final maxChapter = await _repo.chapterCount(widget.book);
    if (target > maxChapter) return;
    setState(() => _chapter = target);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.book} $_chapter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _goToChapter(-1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _goToChapter(1),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              itemCount: _verses.length,
              itemBuilder: (context, index) {
                final v = _verses[index];
                final isBookmarked = _bookmarkedVerseIds.contains(v.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, top: 10),
                          child: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style.copyWith(
                                    fontSize: 17,
                                    height: 1.5,
                                  ),
                              children: [
                                TextSpan(
                                  text: '${v.verse} ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                TextSpan(text: v.text),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.star : Icons.star_border,
                          color: isBookmarked
                              ? Colors.amber
                              : Theme.of(context).colorScheme.outline,
                          size: 20,
                        ),
                        onPressed: () => _toggleBookmark(v),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
