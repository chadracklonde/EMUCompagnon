import 'package:flutter/material.dart';
import '../../../core/models/hymn.dart';
import '../../../core/services/reading_history_service.dart';
import '../repository/hymns_repository.dart';
import 'hymn_detail_screen.dart';

/// A hymn opened from the hymnal: swiping left or right moves to the next
/// or previous number, as one turns the pages of the book.
class HymnPagerScreen extends StatefulWidget {
  final Hymn hymn;

  /// The hymnal in order, when the caller already has it; loaded otherwise.
  final List<Hymn>? hymns;
  const HymnPagerScreen({super.key, required this.hymn, this.hymns});

  @override
  State<HymnPagerScreen> createState() => _HymnPagerScreenState();
}

class _HymnPagerScreenState extends State<HymnPagerScreen> {
  List<Hymn>? _hymns;
  PageController? _controller;

  @override
  void initState() {
    super.initState();
    ReadingHistoryService.saveLastHymnRead(widget.hymn.number, widget.hymn.title);
    final known = widget.hymns;
    if (known != null) {
      _setHymns(known);
    } else {
      HymnsRepository().getAll().then((all) {
        if (mounted) setState(() => _setHymns(all));
      }).catchError((_) {
        // Without the hymnal the hymn is still shown, only without swiping.
      });
    }
  }

  void _setHymns(List<Hymn> all) {
    final index = all.indexWhere((h) => h.id == widget.hymn.id);
    if (index < 0) return;
    _hymns = all;
    _controller = PageController(initialPage: index);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hymns = _hymns;
    if (hymns == null) {
      return HymnDetailScreen(hymn: widget.hymn, recordHistory: false);
    }
    return PageView.builder(
      controller: _controller,
      itemCount: hymns.length,
      onPageChanged: (i) =>
          ReadingHistoryService.saveLastHymnRead(hymns[i].number, hymns[i].title),
      itemBuilder: (context, i) => HymnDetailScreen(
        key: ValueKey(hymns[i].id),
        hymn: hymns[i],
        recordHistory: false,
      ),
    );
  }
}
