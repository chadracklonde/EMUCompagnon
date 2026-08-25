import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/models/verse.dart';
import '../../../core/models/bookmark.dart';
import '../../../core/models/highlight.dart';
import '../../../core/settings/app_settings.dart';
import '../repository/bible_repository.dart';
import '../../favorites/repository/bookmark_repository.dart';
import '../../highlights/repository/highlight_repository.dart';
import '../../notes/screens/notes_sheet.dart';
import '../../../shared/services/image_share_service.dart';
import '../../../shared/widgets/text_settings_popup.dart';
import '../../../shared/widgets/highlight_color_picker.dart';
import '../../../core/services/reading_history_service.dart';

class ChapterScreen extends StatefulWidget {
  final String book;
  final int chapter;
  final String version;
  /// If set, the screen scrolls to and briefly flashes this verse on
  /// open — used when arriving from a tapped Bible-reference link. This
  /// is a temporary visual cue, distinct from a persistent color highlight.
  final int? highlightVerse;

  const ChapterScreen({
    super.key,
    required this.book,
    required this.chapter,
    this.version = 'LSG1910',
    this.highlightVerse,
  });

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  final _repo = BibleRepository();
  final _bookmarkRepo = BookmarkRepository();
  final _highlightRepo = HighlightRepository();
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};

  List<Verse> _verses = [];
  Set<int> _bookmarkedVerseIds = {};
  Map<int, String> _highlightColors = {}; // verse.id -> hex color
  bool _loading = true;
  late int _chapter;
  int? _flashedVerseNumber;

  @override
  void initState() {
    super.initState();
    _chapter = widget.chapter;
    _flashedVerseNumber = widget.highlightVerse;
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final verses = await _repo.getChapter(widget.book, _chapter, version: widget.version);
    final bookmarks = await _bookmarkRepo.listByType(BookmarkType.verse);
    final bookmarkedIds = bookmarks.map((b) => b.refId).toSet();
    final highlightColors = await _highlightRepo.getAllColorsFor(BookmarkType.verse);
    _verseKeys
      ..clear()
      ..addEntries(verses.map((v) => MapEntry(v.verse, GlobalKey())));
    ReadingHistoryService.saveLastBibleRead(widget.book, _chapter);
    if (mounted) {
      setState(() {
        _verses = verses;
        _bookmarkedVerseIds = verses
            .where((v) => bookmarkedIds.contains(v.id))
            .map((v) => v.id)
            .toSet();
        _highlightColors = highlightColors;
        _loading = false;
      });
      if (_flashedVerseNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFlashed());
      }
    }
  }

  void _scrollToFlashed() {
    final key = _verseKeys[_flashedVerseNumber];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _flashedVerseNumber = null);
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

  Future<void> _pickHighlight(Verse v) async {
    final result = await showHighlightColorPicker(context, current: _highlightColors[v.id]);
    if (result == null) return;
    if (result == 'remove') {
      await _highlightRepo.remove(BookmarkType.verse, v.id);
      setState(() => _highlightColors.remove(v.id));
    } else {
      await _highlightRepo.setColor(BookmarkType.verse, v.id, result);
      setState(() => _highlightColors[v.id] = result);
    }
  }

  void _showVerseActions(Verse v) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.border_color_outlined),
              title: const Text('Surligner'),
              onTap: () {
                Navigator.pop(context);
                _pickHighlight(v);
              },
            ),
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
    final maxChapter = await _repo.chapterCount(widget.book, version: widget.version);
    if (target > maxChapter) return;
    _flashedVerseNumber = null;
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
            icon: const Icon(Icons.text_fields),
            tooltip: 'Taille du texte',
            onPressed: () => showTextSettingsPopup(context),
          ),
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
          : GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -250) {
                  _goToChapter(1);
                } else if (velocity > 250) {
                  _goToChapter(-1);
                }
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: _verses.length,
                itemBuilder: (context, index) {
                  final v = _verses[index];
                  final isBookmarked = _bookmarkedVerseIds.contains(v.id);
                  final isFlashed = _flashedVerseNumber == v.verse;
                  final highlightHex = _highlightColors[v.id];

                  Color backgroundColor;
                  if (isFlashed) {
                    backgroundColor = Theme.of(context).colorScheme.primaryContainer;
                  } else if (highlightHex != null) {
                    backgroundColor = HighlightColors.colorFor(highlightHex).withValues(alpha: 0.55);
                  } else {
                    backgroundColor = Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.35);
                  }

                  return AnimatedContainer(
                    key: _verseKeys[v.verse],
                    duration: const Duration(milliseconds: 400),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: isFlashed
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
                                      color: highlightHex != null ? Colors.black87 : null,
                                    ),
                                children: [
                                  TextSpan(
                                    text: '${v.verse}  ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: highlightHex != null
                                          ? Colors.black87
                                          : Theme.of(context).colorScheme.primary,
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
            ),
    );
  }
}
