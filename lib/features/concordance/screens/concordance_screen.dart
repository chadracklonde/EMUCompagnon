import '../../../core/settings/app_settings.dart';
import '../../../core/l10n/app_strings.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_cards.dart';
import 'dart:async';
import '../../../core/models/verse.dart';
import '../../bible/repository/bible_repository.dart';
import '../../bible/screens/chapter_screen.dart';
import '../../../shared/bible_book_names.dart';

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
    final locale = context.watch<AppSettings>().locale;
    String t(String key) => AppStrings.t(key, locale);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AppBarSearchField(
            controller: _controller,
            hint: t('concordance_hint'),
            onChanged: _onChanged,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? EmptyState(
                  icon: _controller.text.trim().isEmpty ? Icons.manage_search : Icons.search_off,
                  message: _controller.text.trim().isEmpty
                      ? t('concordance_empty')
                      : t('no_results'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(top: 4, bottom: 24),
                  // First item: how many verses matched.
                  itemCount: _results.length + 1,
                  separatorBuilder: (_, i) => i == 0
                      ? const SizedBox.shrink()
                      : const Divider(indent: 20, endIndent: 20),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                        child: Text(
                          _results.length == 1
                              ? t('verse_one')
                              : AppStrings.tf('verses_n', context.read<AppSettings>().locale, {'n': _results.length}),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.of(context).muted,
                          ),
                        ),
                      );
                    }
                    final v = _results[index - 1];
                    return ResultRow(
                      title: context.bookReference(v.reference),
                      subtitle: v.text,
                      subtitleMaxLines: 3,
                      accentTitle: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChapterScreen(
                            book: v.book,
                            chapter: v.chapter,
                            highlightVerse: v.verse,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
