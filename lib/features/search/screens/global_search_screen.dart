import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_cards.dart';
import '../repository/global_search_repository.dart';
import '../../bible/screens/chapter_screen.dart';
import '../../hymns/screens/hymn_detail_screen.dart';
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
  bool _loading = false;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  void _onChanged(String query) {
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
    _search(query);
  }

  Future<void> _clearHistory() async {
    await SearchHistoryService.clear();
    if (mounted) setState(() => _history = []);
  }

  @override
  Widget build(BuildContext context) {
    final r = _results;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AppBarSearchField(
            controller: _controller,
            hint: "Rechercher dans toute l'app…",
            onChanged: _onChanged,
          ),
        ),
        // Tabs only make sense once there are results to split.
        bottom: r == null || r.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Bible (${r.verses.length})'),
                  Tab(text: 'Cantiques (${r.hymns.length})'),
                  Tab(text: 'Dictionnaire (${r.dictionaryEntries.length})'),
                ],
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : r == null
              ? _HistoryView(
                  history: _history,
                  onTap: _searchFromHistory,
                  onClear: _clearHistory,
                )
              : r.isEmpty
                  ? const EmptyState(icon: Icons.search_off, message: 'Aucun résultat.')
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _VerseResults(verses: r.verses),
                        _HymnResults(hymns: r.hymns),
                        _DictionaryResults(entries: r.dictionaryEntries),
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
        message: 'Tapez un mot pour chercher dans la Bible, les cantiques et le dictionnaire.',
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
            builder: (_) => HymnDetailScreen(hymn: h),
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
