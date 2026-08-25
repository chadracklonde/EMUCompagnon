import 'dart:async';
import 'package:flutter/material.dart';
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
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher dans toute l\'app…',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Bible${r != null ? ' (${r.verses.length})' : ''}'),
            Tab(text: 'Cantiques${r != null ? ' (${r.hymns.length})' : ''}'),
            Tab(text: 'Dictionnaire${r != null ? ' (${r.dictionaryEntries.length})' : ''}'),
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
                  ? const Center(child: Text('Aucun résultat'))
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
      return const Center(child: Text('Tapez un mot pour chercher partout'));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recherches récentes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: onClear, child: const Text('Effacer')),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history
                .map((q) => ActionChip(
                      avatar: const Icon(Icons.history, size: 16),
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

class _VerseResults extends StatelessWidget {
  final List verses;
  const _VerseResults({required this.verses});

  @override
  Widget build(BuildContext context) {
    if (verses.isEmpty) {
      return const Center(child: Text('Aucun verset trouvé'));
    }
    return ListView.separated(
      itemCount: verses.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final v = verses[i];
        return ListTile(
          title: Text(v.reference, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(v.text, maxLines: 2, overflow: TextOverflow.ellipsis),
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
      return const Center(child: Text('Aucun cantique trouvé'));
    }
    return ListView.separated(
      itemCount: hymns.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final h = hymns[i];
        return ListTile(
          leading: CircleAvatar(child: Text(h.number)),
          title: Text(h.title),
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
      return const Center(child: Text('Aucune entrée trouvée'));
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final e = entries[i];
        return ListTile(
          title: Text(e.term, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(e.definition, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DictionaryDetailScreen(entry: e),
          )),
        );
      },
    );
  }
}
