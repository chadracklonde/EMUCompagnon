import 'package:flutter/material.dart';
import '../../../core/models/hymn.dart';
import '../../../core/theme/app_theme.dart';
import '../../hymns/screens/hymn_detail_screen.dart';

/// Sings through a list: one hymn at a time, with previous / next at the
/// bottom so the leader moves on without going back to the list.
class HymnListPlayerScreen extends StatefulWidget {
  final String listName;
  final List<Hymn> hymns;
  final int initialIndex;
  const HymnListPlayerScreen({
    super.key,
    required this.listName,
    required this.hymns,
    this.initialIndex = 0,
  });

  @override
  State<HymnListPlayerScreen> createState() => _HymnListPlayerScreenState();
}

class _HymnListPlayerScreenState extends State<HymnListPlayerScreen> {
  late int _index = widget.initialIndex.clamp(0, widget.hymns.length - 1);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final hymns = widget.hymns;
    final hasPrevious = _index > 0;
    final hasNext = _index < hymns.length - 1;

    return HymnDetailScreen(
      // A new key per hymn: fresh favourite state, scrolled back to the top.
      key: ValueKey(hymns[_index].id),
      hymn: hymns[_index],
      bottomBar: Material(
        color: palette.card,
        child: SafeArea(
          top: false,
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: palette.border))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Cantique précédent',
                    onPressed: hasPrevious ? () => setState(() => _index--) : null,
                    icon: const Icon(Icons.skip_previous),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_index + 1} / ${hymns.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          hasNext
                              ? 'Ensuite : n° ${hymns[_index + 1].number}'
                              : widget.listName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: palette.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cantique suivant',
                    onPressed: hasNext ? () => setState(() => _index++) : null,
                    icon: const Icon(Icons.skip_next),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
