import '../../../shared/widgets/keep_awake.dart';
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
import '../../../shared/services/text_share_service.dart';
import '../../../shared/widgets/text_settings_popup.dart';
import '../../../shared/widgets/highlight_color_picker.dart';
import '../../../core/services/reading_history_service.dart';
import '../../memorization/repository/memory_card_repository.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../core/theme/app_theme.dart';
import '../../reading_plan/services/reading_plan_service.dart';

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
  // Position of this chapter in the reading plan, and whether it is read.
  int? _planIndex;
  bool _isRead = false;
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
    int? planIndex;
    var isRead = false;
    try {
      planIndex = await ReadingPlanService.indexOf(widget.book, _chapter);
      if (planIndex != null) {
        isRead = (await ReadingPlanService.getCompleted()).contains(planIndex);
      }
    } catch (_) {
      // The "read" button is a convenience: reading works without it.
    }
    _verseKeys
      ..clear()
      ..addEntries(verses.map((v) => MapEntry(v.verse, GlobalKey())));
    ReadingHistoryService.saveLastBibleRead(widget.book, _chapter);
    if (mounted) {
      setState(() {
        _verses = verses;
        _bookmarkedVerseIds =
            verses.where((v) => bookmarkedIds.contains(v.id)).map((v) => v.id).toSet();
        _highlightColors = highlightColors;
        _chapterCount = chapterCount;
        _planIndex = planIndex;
        _isRead = isRead;
        _loading = false;
      });
      if (_flashedVerseNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFlashed());
      }
    }
  }

  /// Brings the verse to highlight into view.
  ///
  /// The list builds its verses lazily, so a verse far down the chapter
  /// has no widget yet and cannot be scrolled to directly: step towards
  /// it a screen at a time until it exists, then settle on it.
  void _scrollToFlashed({int attempt = 0}) {
    if (!mounted) return;
    final target = _flashedVerseNumber;
    if (target == null) return;
    if (attempt == 0) {
      Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _flashedVerseNumber = null);
      });
    }

    final ctx = _verseKeys[target]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: Duration(milliseconds: attempt == 0 ? 400 : 200),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
      return;
    }
    if (attempt >= 60 || !_scrollController.hasClients) return;

    // Which verses exist right now tells us which way to go.
    final built = _verseKeys.entries
        .where((e) => e.value.currentContext != null)
        .map((e) => e.key)
        .toList();
    final position = _scrollController.position;
    final forward = built.isEmpty || target > built.reduce((a, b) => a > b ? a : b);
    final step = position.viewportDimension * 0.9;
    final next = (position.pixels + (forward ? step : -step))
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (next == position.pixels) return; // nowhere left to go
    _scrollController.jumpTo(next);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFlashed(attempt: attempt + 1));
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
                _bookmarkedVerseIds.contains(v.id) ? 'Retirer des favoris' : 'Ajouter aux favoris',
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
              leading: const Icon(Icons.share_outlined),
              title: const Text('Partager le texte'),
              onTap: () {
                Navigator.pop(context);
                TextShareService.share(
                  TextShareService.verseText(reference: v.reference, text: v.text),
                  subject: v.reference,
                );
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

  /// Ticks (or unticks) this chapter in the reading plan.
  Future<void> _toggleRead() async {
    final index = _planIndex;
    if (index == null) return;
    final nowRead = !_isRead;
    await ReadingPlanService.setChapterRead(index, nowRead);
    if (!mounted) return;
    setState(() => _isRead = nowRead);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          nowRead
              ? '${widget.book} $_chapter marqué comme lu dans le plan de lecture.'
              : '${widget.book} $_chapter n\'est plus marqué comme lu.',
        ),
      ));
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

    return KeepAwake(child: Scaffold(
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
                        isRead: _isRead,
                        onToggleRead: _planIndex == null ? null : _toggleRead,
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
                    final textColor =
                        highlightHex != null && !isFlashed ? Colors.black87 : scheme.onSurface;

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
    ));
  }
}

/// Shown after the last verse: mark the chapter as read in the reading
/// plan, then previous / next chapter — so the reader never has to leave
/// the text to keep their plan up to date.
class _ChapterNav extends StatelessWidget {
  final bool isRead;

  /// Null when the chapter is not part of the plan (button hidden).
  final VoidCallback? onToggleRead;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  const _ChapterNav({
    required this.isRead,
    required this.onToggleRead,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
      child: Column(
        children: [
          if (onToggleRead != null) ...[
            SizedBox(
              width: double.infinity,
              child: isRead
                  ? OutlinedButton.icon(
                      onPressed: onToggleRead,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Chapitre lu'),
                    )
                  : FilledButton.tonalIcon(
                      onPressed: onToggleRead,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Marquer comme lu'),
                    ),
            ),
            const SizedBox(height: 12),
          ],
          _buildArrows(),
        ],
      ),
    );
  }

  Widget _buildArrows() {
    return Row(
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
    );
  }
}
