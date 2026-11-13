import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bible_version.dart';
import '../../../core/settings/app_settings.dart';
import '../repository/bible_repository.dart';
import 'chapter_list_screen.dart';
import 'chapter_screen.dart';
import '../../concordance/screens/concordance_screen.dart';
import '../../search/screens/global_search_screen.dart';
import '../../../core/services/reading_history_service.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../shared/widgets/version_picker.dart';
import '../../../shared/bible_book_names.dart';

enum TestamentFilter { all, oldTestament, newTestament }

class BooksScreen extends StatefulWidget {
  final TestamentFilter filter;
  const BooksScreen({super.key, this.filter = TestamentFilter.all});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  static const _ancienTestament = 39;
  ({String book, int chapter})? _lastRead;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
  }

  void _loadLastRead() {
    ReadingHistoryService.getLastBibleRead().then((r) {
      if (mounted) setState(() => _lastRead = r);
    });
  }

  /// Pushes [screen], then refreshes "Reprendre la lecture" — this tab
  /// stays alive in the shell, so its state would otherwise go stale.
  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _loadLastRead();
  }

  Future<void> _pickVersion(AppSettings settings) async {
    final chosen = await showVersionPicker(context, current: settings.bibleVersion);
    if (chosen != null) {
      await settings.setBibleVersion(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final version = settings.bibleVersion;
    final locale = settings.locale;
    String t(String key) => AppStrings.t(key, locale);
    final versionInfo = BibleVersions.byCode(version);
    final allBooks = BibleRepository.books;
    final palette = AppPalette.of(context);

    final oldTestament = allBooks.sublist(0, _ancienTestament);
    final newTestament = allBooks.sublist(_ancienTestament);

    final appBarTitle = switch (widget.filter) {
      TestamentFilter.oldTestament => t('old_testament'),
      TestamentFilter.newTestament => t('new_testament'),
      TestamentFilter.all => t('nav_bible'),
    };

    Widget bookGroup(List<String> books) => AppCard(
          child: Column(
            children: [
              for (var i = 0; i < books.length; i++) ...[
                if (i > 0) Divider(indent: 16, color: palette.border),
                _BookRow(
                  book: books[i],
                  onTap: () => _open(ChapterListScreen(book: books[i], version: version)),
                ),
              ],
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(appBarTitle),
            Text(
              versionInfo.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: palette.muted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: 'Version de la Bible',
            onPressed: () => _pickVersion(settings),
          ),
          IconButton(
            icon: const Icon(Icons.manage_search),
            tooltip: 'Concordance',
            onPressed: () => _open(const ConcordanceScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Recherche globale (Bible, Cantiques, Dictionnaire)',
            onPressed: () => _open(const GlobalSearchScreen()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (widget.filter == TestamentFilter.all && _lastRead != null) ...[
              AppCard(
                child: AppRow(
                  icon: Icons.history,
                  title: t('resume_reading'),
                  subtitle: '${context.bookName(_lastRead!.book)} ${_lastRead!.chapter}',
                  onTap: () => _open(ChapterScreen(
                    book: _lastRead!.book,
                    chapter: _lastRead!.chapter,
                    version: version,
                  )),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (widget.filter != TestamentFilter.newTestament) ...[
              if (widget.filter == TestamentFilter.all) SectionTitle(t('old_testament')),
              bookGroup(oldTestament),
            ],
            if (widget.filter == TestamentFilter.all) const SizedBox(height: 24),
            if (widget.filter != TestamentFilter.oldTestament) ...[
              if (widget.filter == TestamentFilter.all) SectionTitle(t('new_testament')),
              bookGroup(newTestament),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  final String book;
  final VoidCallback onTap;
  const _BookRow({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.bookName(book),
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: palette.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
