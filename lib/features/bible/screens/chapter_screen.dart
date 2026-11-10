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
import '../../memorization/repository/memory_card_repository.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../core/theme/app_theme.dart';

class ChapterScreen extends StatefulWidget {
  final String book;
  final int chapter;
  final String version;
  /// If set, the screen scrolls to and briefly flashes this verse on
  /// open — used when arriving from a tapped Bible-reference link. This
  /// is a temporary visual cue, distinct from a persistent color highlight.
  final int? highlightVerse;
  /// False when embedded as the detail pane of a wide-screen master-detail
  /// layout — no back button needed there.
  final bool showBackButton;

  const ChapterScreen({
    super.key,
    required this.book,
    required this.chapter,
    this.version = 'LSG1910',
    this.highlightVerse,
    this.showBackButton = true,
  });

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  final _repo = BibleRepository();
  final _bookmarkRepo = BookmarkRepository();
  final _highlightRepo = HighlightRepository();
  final _memoryCardRepo = MemoryCardRepository();
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};

  List<Verse> _verses = [];
  Set<int> _bookmarkedVerseIds = {};
  Map<int, String> _highlightColors = {}; // verse.id -> hex color
  bool _loading = true;
  late int _chapter;
  int? _chapterCount;
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
    final chapterCount =
        _chapterCount ?? await _repo.chapterCount(widget.book, version: widget.version);
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
        _chapterCount = chapterCount;
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

  Future<void> _addToMemorization(Verse v) async {
    final already = await _memoryCardRepo.isAlreadyAdded(v.book, v.chapter, v.verse);
    if (already) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ce verset est déjà dans votre deck de mémorisation.')),
        );
      }
      return;
    }
    await _memoryCardRepo.addCard(
      book: v.book,
      chapter: v.chapter,
      verse: v.verse,
      verseText: v.text,
      referenceLabel: v.reference,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verset ajouté à la mémorisation.')),
      );
    }
  }

  void _showVerseActions(Verse v) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                v.reference,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: Icon(
                _bookmarkedVerseIds.contains(v.id) ? Icons.star : Icons.star_outline,
              ),
              title: Text(
                _bookmarkedVerseIds.contains(v.id)
                    ? 'Retirer des favoris'
                    : 'Ajouter aux favoris',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleBookmark(v);
              },
            ),
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
            ListTile(
              leading: const Icon(Icons.psychology_outlined),
              title: const Text('Mémoriser ce verset'),
              onTap: () {
                Navigator.pop(context);
                _addToMemorization(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToChapter(int delta) async {
    final target = _chapter + delta;
    if (target < 1) return;
    final maxChapter =
        _chapterCount ?? await _repo.chapterCount(widget.book, version: widget.version);
    if (target > maxChapter || !mounted) return;
    _flashedVerseNumber = null;
    setState(() => _chapter = target);
    await _load();
    // The list is rebuilt after loading: go back to the top once it is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lineHeightScale = context.watch<AppSettings>().lineHeightScale;
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hasPrevious = _chapter > 1;
    final hasNext = _chapterCount != null && _chapter < _chapterCount!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        title: Text('${widget.book} $_chapter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Taille du texte',
            onPressed: () => showTextSettingsPopup(context),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Chapitre précédent',
            onPressed: hasPrevious ? () => _goToChapter(-1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Chapitre suivant',
            onPressed: hasNext ? () => _goToChapter(1) : null,
          ),
          const SizedBox(width: 4),
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
              child: ReadingWidthConstraint(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
                  // One extra item: the previous/next chapter buttons.
                  itemCount: _verses.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _verses.length) {
                      return _ChapterNav(
                        onPrevious: hasPrevious ? () => _goToChapter(-1) : null,
                        onNext: hasNext ? () => _goToChapter(1) : null,
                      );
                    }
                    final v = _verses[index];
                    final isBookmarked = _bookmarkedVerseIds.contains(v.id);
                    final isFlashed = _flashedVerseNumber == v.verse;
                    final highlightHex = _highlightColors[v.id];

                    // Plain running text: a verse only gets a background
                    // when it is highlighted or briefly flashed.
                    final Color backgroundColor;
                    if (isFlashed) {
                      backgroundColor = palette.accentSoft;
                    } else if (highlightHex != null) {
                      backgroundColor =
                          HighlightColors.colorFor(highlightHex).withValues(alpha: 0.55);
                    } else {
                      backgroundColor = Colors.transparent;
                    }
                    final textColor = highlightHex != null && !isFlashed
                        ? Colors.black87
                        : scheme.onSurface;

                    return AnimatedContainer(
                      key: _verseKeys[v.verse],
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isFlashed ? palette.accent : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: Semantics(
                          onTapHint: 'ouvrir les actions du verset',
                          onLongPressHint: 'copier le verset',
                          child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _showVerseActions(v),
                          onLongPress: () => _copyVerse(v),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 17.5,
                                  height: 1.6 * lineHeightScale,
                                  color: textColor,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${v.verse}\u00A0\u00A0',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: highlightHex != null && !isFlashed
                                          ? Colors.black87
                                          : palette.accent,
                                    ),
                                  ),
                                  TextSpan(text: v.text),
                                  if (isBookmarked)
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Icon(
                                          Icons.star,
                                          size: 16,
                                          color: highlightHex != null && !isFlashed
                                              ? Colors.black87
                                              : palette.accent,
                                          semanticLabel: 'Favori',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

/// Previous / next chapter buttons shown after the last verse, so the
/// reader does not have to reach back up to the app bar.
class _ChapterNav extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  const _ChapterNav({required this.onPrevious, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Précédent'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: onNext,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Suivant'),
            ),
          ),
        ],
      ),
    );
  }
}
