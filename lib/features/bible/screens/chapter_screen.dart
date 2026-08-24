import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/models/verse.dart';
import '../../../core/models/bookmark.dart';
import '../../../core/settings/app_settings.dart';
import '../repository/bible_repository.dart';
import '../../favorites/repository/bookmark_repository.dart';
import '../../notes/screens/notes_sheet.dart';
import '../../../shared/services/image_share_service.dart';

class ChapterScreen extends StatefulWidget {
  final String book;
  final int chapter;
  /// If set, the screen scrolls to and briefly highlights this verse on
  /// open — used when arriving from a tapped Bible-reference link.
  final int? highlightVerse;

  const ChapterScreen({
    super.key,
    required this.book,
    required this.chapter,
    this.highlightVerse,
  });

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  final _repo = BibleRepository();
  final _bookmarkRepo = BookmarkRepository();
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};

  List<Verse> _verses = [];
  Set<int> _bookmarkedVerseIds = {};
  bool _loading = true;
  late int _chapter;
  int? _highlightedVerseNumber;

  @override
  void initState() {
    super.initState();
    _chapter = widget.chapter;
    _highlightedVerseNumber = widget.highlightVerse;
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final verses = await _repo.getChapter(widget.book, _chapter);
    final bookmarks = await _bookmarkRepo.listByType(BookmarkType.verse);
    final bookmarkedIds = bookmarks.map((b) => b.refId).toSet();
    _verseKeys
      ..clear()
      ..addEntries(verses.map((v) => MapEntry(v.verse, GlobalKey())));
    if (mounted) {
      setState(() {
        _verses = verses;
        _bookmarkedVerseIds = verses
            .where((v) => bookmarkedIds.contains(v.id))
            .map((v) => v.id)
            .toSet();
        _loading = false;
      });
      if (_highlightedVerseNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHighlighted());
      }
    }
  }

  void _scrollToHighlighted() {
    final key = _verseKeys[_highlightedVerseNumber];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
    // Fade the highlight out after a few seconds.
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _highlightedVerseNumber = null);
    });
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

  void _copyVerse(Verse v) {
    Clipboard.setData(ClipboardData(text: '${v.text}\n— ${v.reference}'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${v.reference} copié'), duration: const Duration(seconds: 2)),
    );
  }

  void _openNotes(Verse v) {
    showNotesSheet(context, type: BookmarkType.verse, refId: v.id, label: v.reference);
  }

  Future<void> _shareAsImage(Verse v) async {
    await ImageShareService.shareVerse(context, reference: v.reference, text: v.text);
  }

  void _showVerseActions(Verse v) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier le texte'),
              onTap: () {
                Navigator.pop(context);
                _copyVerse(v);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: const Text('Ajouter une note'),
              onTap: () {
                Navigator.pop(context);
                _openNotes(v);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Partager comme image'),
              onTap: () {
                Navigator.pop(context);
                _shareAsImage(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _goToChapter(int delta) async {
    final target = _chapter + delta;
    if (target < 1) return;
    final maxChapter = await _repo.chapterCount(widget.book);
    if (target > maxChapter) return;
    _highlightedVerseNumber = null;
    setState(() => _chapter = target);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final lineHeightScale = context.watch<AppSettings>().lineHeightScale;

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
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: _verses.length,
              itemBuilder: (context, index) {
                final v = _verses[index];
                final isBookmarked = _bookmarkedVerseIds.contains(v.id);
                final isHighlighted = _highlightedVerseNumber == v.verse;

                return AnimatedContainer(
                  key: _verseKeys[v.verse],
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: isHighlighted
                        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                        : null,
                  ),
                  child: GestureDetector(
                    onLongPress: () => _copyVerse(v),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style.copyWith(
                                    fontSize: 17,
                                    height: 1.5 * lineHeightScale,
                                  ),
                              children: [
                                TextSpan(
                                  text: '${v.verse}  ',
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
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: Theme.of(context).colorScheme.outline,
                            size: 20,
                          ),
                          onPressed: () => _showVerseActions(v),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
