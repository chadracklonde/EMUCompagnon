import 'package:flutter/material.dart';
import '../../../core/models/hymn.dart';
import '../../../core/models/bookmark.dart';
import '../../favorites/repository/bookmark_repository.dart';

class HymnDetailScreen extends StatefulWidget {
  final Hymn hymn;
  const HymnDetailScreen({super.key, required this.hymn});

  @override
  State<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends State<HymnDetailScreen> {
  final _bookmarkRepo = BookmarkRepository();
  bool _isBookmarked = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookmarked = await _bookmarkRepo.isBookmarked(
      BookmarkType.hymn,
      widget.hymn.id,
    );
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
        _loading = false;
      });
    }
  }

  Future<void> _toggle() async {
    final nowBookmarked = await _bookmarkRepo.toggle(
      BookmarkType.hymn,
      widget.hymn.id,
      note: '${widget.hymn.number} — ${widget.hymn.title}',
    );
    setState(() => _isBookmarked = nowBookmarked);
  }

  @override
  Widget build(BuildContext context) {
    final hymn = widget.hymn;
    return Scaffold(
      appBar: AppBar(
        title: Text('N° ${hymn.number}'),
        actions: [
          if (!_loading)
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.star : Icons.star_border,
                color: _isBookmarked ? Colors.amber : null,
              ),
              tooltip: _isBookmarked ? 'Retirer des favoris' : 'Ajouter aux favoris',
              onPressed: _toggle,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hymn.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (hymn.key != null) ...[
              const SizedBox(height: 4),
              Text(
                'Tonalité : ${hymn.key}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              hymn.lyrics,
              style: const TextStyle(fontSize: 17, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
