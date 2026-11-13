import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../repository/bible_repository.dart';
import 'chapter_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/responsive.dart';
import '../../../shared/bible_book_names.dart';

class ChapterListScreen extends StatefulWidget {
  final String book;
  /// Null : la version choisie dans les réglages (qui suit la langue).
  final String? version;
  const ChapterListScreen({super.key, required this.book, this.version});

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  final _repo = BibleRepository();
  int? _chapterCount;
  String? _shownVersion;

  String get _ver => widget.version ?? BibleRepository.activeVersion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = widget.version ?? Provider.of<AppSettings>(context).bibleVersion;
    if (_shownVersion != null && _shownVersion != v) {
      _shownVersion = v;
      _load();
    }
    _shownVersion ??= v;
  }
  // Only meaningful in the wide (master-detail) layout.
  int? _selectedChapter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final count = await _repo.chapterCount(widget.book, version: _ver);
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
            version: _ver,
          ),
        ),
      );
    }
  }

  Widget _buildGrid(bool isWide) {
    return _chapterCount == null
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 4 : 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
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
      appBar: AppBar(title: Text(context.bookName(widget.book, version: _ver))),
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
                            AppStrings.t('select_chapter', context.read<AppSettings>().locale),
                            style: TextStyle(color: Theme.of(context).colorScheme.outline),
                          ),
                        )
                      : ChapterScreen(
                          book: widget.book,
                          chapter: _selectedChapter!,
                          version: _ver,
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
    final palette = AppPalette.of(context);
    return Material(
      color: selected ? palette.accent : palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? palette.accent : palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            '$chapter',
            semanticsLabel: AppStrings.tf('chapter_n', context.read<AppSettings>().locale, {'n': chapter}),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
