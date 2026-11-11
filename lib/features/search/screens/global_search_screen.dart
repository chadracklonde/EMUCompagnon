import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/bible_quick_reference.dart';
import '../../../shared/bible_reference_parser.dart';
import '../../bible/repository/bible_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_cards.dart';
import '../repository/content_search.dart';
import '../repository/global_search_repository.dart';
import '../../church_texts/data/church_texts_data.dart';
import '../../church_texts/screens/church_text_screen.dart';
import '../../liturgy/data/sacraments_data.dart';
import '../../liturgy/screens/liturgical_calendar_screen.dart';
import '../../liturgy/screens/liturgical_period_detail_screen.dart';
import '../../liturgy/screens/sacraments_screen.dart';
import '../../liturgy/screens/worship_order_screen.dart';
import '../../liturgy/services/liturgical_calendar_service.dart';
import '../../bible/screens/chapter_screen.dart';
import '../../hymns/screens/hymn_pager_screen.dart';
import '../../dictionary/screens/dictionary_detail_screen.dart';
import '../../../core/services/search_history_service.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen>
    with SingleTickerProviderStateMixin {
  final _repo = GlobalSearchRepository();
  final _controller = TextEditingController();
  late final TabController _tabController;
  Timer? _debounce;
  GlobalSearchResults? _results;
  // Set when what is typed is itself a Bible reference ("Jean 3.16").
  BibleReferenceMatch? _reference;
  bool _loading = false;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    SearchHistoryService.get().then((h) {
      if (mounted) setState(() => _history = h);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Offers to jump straight to a passage when the query is a reference
  /// to a chapter that exists.
  Future<void> _updateReference(String query) async {
    final match = BibleQuickReference.parse(query);
    if (match == null) {
      if (_reference != null) setState(() => _reference = null);
      return;
    }
    final chapters = await BibleRepository().chapterCount(match.book);
    if (!mounted || _controller.text != query) return;
    setState(() => _reference = match.chapter <= chapters ? match : null);
  }

  void _openReference(BibleReferenceMatch match) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChapterScreen(
        book: match.book,
        chapter: match.chapter,
        highlightVerse: match.verse,
      ),
    ));
  }

  void _onChanged(String query) {
    _updateReference(query);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() => _loading = true);
    final results = await _repo.search(query);
    await SearchHistoryService.add(query);
    final history = await SearchHistoryService.get();
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
        _history = history;
      });
    }
  }

  void _searchFromHistory(String query) {
    _controller.text = query;
    _updateReference(query);
    _search(query);
  }

  Future<void> _clearHistory() async {
    await SearchHistoryService.clear();
    if (mounted) setState(() => _history = []);
  }

  @override
  Widget build(BuildContext context) {
    final r = _results;
    final reference = _reference;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AppBarSearchField(
            controller: _controller,
            hint: 'Mot, cantique ou référence (Jean 3.16)…',
            onChanged: _onChanged,
          ),
        ),
        // Tabs only make sense once there are results to split.
        bottom: r == null || r.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'Bible (${r.verses.length})'),
                  Tab(text: 'Cantiques (${r.hymns.length})'),
                  Tab(text: 'Dictionnaire (${r.dictionaryEntries.length})'),
                  Tab(text: 'Liturgie et textes (${r.texts.length})'),
                ],
              ),
      ),
      body: Column(
        children: [
          if (reference != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: AppCard(
                child: AppRow(
                  icon: Icons.menu_book_outlined,
                  title: 'Aller à ${reference.book} ${reference.chapter}'
                      '${reference.verse == null ? '' : '.${reference.verse}'}',
                  subtitle: 'Ouvrir ce passage de la Bible',
                  onTap: () => _openReference(reference),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : r == null
                    ? _HistoryView(
                        history: _history,
                        onTap: _searchFromHistory,
                        onClear: _clearHistory,
                      )
                    : r.isEmpty
                        // A reference rarely matches as plain text: the card
                        // above is the answer, so no "no result" message.
                        ? (reference != null
                            ? const SizedBox.shrink()
                            : const EmptyState(
                                icon: Icons.search_off,
                                message: 'Aucun résultat.',
                              ))
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _VerseResults(verses: r.verses),
                              _HymnResults(hymns: r.hymns),
                              _DictionaryResults(entries: r.dictionaryEntries),
                              _TextResults(hits: r.texts),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

class _HistoryView extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;
  const _HistoryView({required this.history, required this.onTap, required this.onClear});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        message: 'Tapez un mot pour chercher dans la Bible, les cantiques, le dictionnaire, la liturgie et les textes de l\'Église.',
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle('Recherches récentes')),
              TextButton(onPressed: onClear, child: const Text('Effacer')),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history
                .map((q) => ActionChip(
                      avatar: Icon(Icons.history, size: 16, color: AppPalette.of(context).muted),
                      label: Text(q),
                      onPressed: () => onTap(q),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

Widget _resultList({required int count, required IndexedWidgetBuilder itemBuilder}) {
  return ListView.separated(
    padding: const EdgeInsets.only(top: 4, bottom: 24),
    itemCount: count,
    separatorBuilder: (_, __) => const Divider(indent: 20, endIndent: 20),
    itemBuilder: itemBuilder,
  );
}

class _VerseResults extends StatelessWidget {
  final List verses;
  const _VerseResults({required this.verses});

  @override
  Widget build(BuildContext context) {
    if (verses.isEmpty) {
      return const EmptyState(icon: Icons.menu_book_outlined, message: 'Aucun verset trouvé.');
    }
    return _resultList(
      count: verses.length,
      itemBuilder: (context, i) {
        final v = verses[i];
        return ResultRow(
          title: v.reference,
          subtitle: v.text,
          subtitleMaxLines: 3,
          accentTitle: true,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChapterScreen(book: v.book, chapter: v.chapter, highlightVerse: v.verse),
          )),
        );
      },
    );
  }
}

class _HymnResults extends StatelessWidget {
  final List hymns;
  const _HymnResults({required this.hymns});

  @override
  Widget build(BuildContext context) {
    if (hymns.isEmpty) {
      return const EmptyState(icon: Icons.music_note_outlined, message: 'Aucun cantique trouvé.');
    }
    return _resultList(
      count: hymns.length,
      itemBuilder: (context, i) {
        final h = hymns[i];
        return ResultRow(
          leading: NumberBadge(h.number),
          title: h.title,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => HymnPagerScreen(hymn: h),
          )),
        );
      },
    );
  }
}

class _DictionaryResults extends StatelessWidget {
  final List entries;
  const _DictionaryResults({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(icon: Icons.auto_stories_outlined, message: 'Aucune entrée trouvée.');
    }
    return _resultList(
      count: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return ResultRow(
          title: e.term,
          subtitle: e.definition,
          subtitleMaxLines: 1,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DictionaryDetailScreen(entry: e),
          )),
        );
      },
    );
  }
}

class _TextResults extends StatelessWidget {
  final List<ContentHit> hits;
  const _TextResults({required this.hits});

  Widget _screenFor(ContentHit hit) {
    switch (hit.kind) {
      case ContentHitKind.churchText:
        final text = ChurchTextsData.byId(hit.id!)!;
        return ChurchTextScreen(text: text, initialHeading: hit.headingIndex);
      case ContentHitKind.worshipOrder:
        return const WorshipOrderScreen();
      case ContentHitKind.sacrament:
        return SacramentDetailScreen(sacrament: SacramentsData.byId(hit.id!));
      case ContentHitKind.liturgicalPeriod:
        final year = LiturgicalCalendarService.churchYearStartFor(DateTime.now());
        for (final instance in LiturgicalCalendarService.periodsForChurchYear(year)) {
          if (instance.period.id == hit.id) {
            return LiturgicalPeriodDetailScreen(instance: instance);
          }
        }
        return const LiturgicalCalendarScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hits.isEmpty) {
      return const EmptyState(
        icon: Icons.auto_stories_outlined,
        message: 'Rien trouvé dans la liturgie ni dans les textes.',
      );
    }
    return _resultList(
      count: hits.length,
      itemBuilder: (context, i) {
        final hit = hits[i];
        return ResultRow(
          title: hit.title,
          subtitle: '${hit.location} — ${hit.excerpt}',
          subtitleMaxLines: 2,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => _screenFor(hit)),
          ),
        );
      },
    );
  }
}
