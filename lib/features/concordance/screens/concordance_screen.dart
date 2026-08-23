import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/models/verse.dart';
import '../../bible/repository/bible_repository.dart';
import '../../bible/screens/chapter_screen.dart';

/// Full-text concordance search across the whole Bible.
class ConcordanceScreen extends StatefulWidget {
  const ConcordanceScreen({super.key});

  @override
  State<ConcordanceScreen> createState() => _ConcordanceScreenState();
}

class _ConcordanceScreenState extends State<ConcordanceScreen> {
  final _repo = BibleRepository();
  final _controller = TextEditingController();
  List<Verse> _results = [];
  bool _loading = false;
  Timer? _debounce;

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final results = await _repo.search(query);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher un mot ou une expression…',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(
                  child: Text(
                    _controller.text.isEmpty
                        ? 'Tapez un mot pour chercher dans toute la Bible'
                        : 'Aucun résultat',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final v = _results[index];
                    return ListTile(
                      title: Text(
                        v.reference,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(v.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChapterScreen(book: v.book, chapter: v.chapter),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
