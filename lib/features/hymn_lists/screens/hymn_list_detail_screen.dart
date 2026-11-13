import '../../../shared/widgets/hymn_audio_mark.dart';
import 'package:flutter/material.dart';
import '../../../core/models/hymn.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../hymns/repository/hymns_repository.dart';
import '../services/hymn_list_service.dart';
import '../widgets/list_dialogs.dart';
import 'hymn_list_player_screen.dart';
import 'hymn_picker_screen.dart';

/// One hymn list: its hymns in order, to reorder, complete and sing through.
class HymnListDetailScreen extends StatefulWidget {
  final String listId;
  const HymnListDetailScreen({super.key, required this.listId});

  @override
  State<HymnListDetailScreen> createState() => _HymnListDetailScreenState();
}

class _HymnListDetailScreenState extends State<HymnListDetailScreen> {
  final _repo = HymnsRepository();
  HymnList? _list;
  // Hymns of the list, in order; a number no longer in the hymnal is left out.
  List<Hymn> _hymns = [];
  bool _loading = true;
  ScaffoldMessengerState? _messenger;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    // The "removed — undo" message belongs to this screen: do not leave
    // it showing (with a dead undo button) on the screen we return to.
    _messenger?.hideCurrentSnackBar();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await HymnListService.get(widget.listId);
    final hymns = <Hymn>[];
    if (list != null) {
      for (final number in list.numbers) {
        final hymn = await _repo.getByNumber(number);
        if (hymn != null) hymns.add(hymn);
      }
    }
    if (!mounted) return;
    setState(() {
      _list = list;
      _hymns = hymns;
      _loading = false;
    });
  }

  Future<void> _saveOrder(List<Hymn> hymns) async {
    if (mounted) setState(() => _hymns = hymns);
    await HymnListService.setNumbers(widget.listId, [for (final h in hymns) h.number]);
  }

  Future<void> _addHymns() async {
    final picked = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => HymnPickerScreen(alreadyIn: [for (final h in _hymns) h.number]),
      ),
    );
    if (picked == null || picked.isEmpty) return;
    await HymnListService.setNumbers(
      widget.listId,
      [for (final h in _hymns) h.number, ...picked],
    );
    await _load();
  }

  Future<void> _remove(Hymn hymn) async {
    final before = _hymns;
    await _saveOrder(_hymns.where((h) => h.number != hymn.number).toList());
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('N° ${hymn.number} retiré de la liste.'),
        action: SnackBarAction(label: 'Annuler', onPressed: () => _saveOrder(before)),
      ));
  }

  Future<void> _rename() async {
    final list = _list;
    if (list == null) return;
    final name = await askListName(context, title: 'Renommer la liste', initial: list.name);
    if (name == null) return;
    await HymnListService.rename(list.id, name);
    await _load();
  }

  Future<void> _delete() async {
    final list = _list;
    if (list == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette liste ?'),
        content: Text(
          '« ${list.name} » sera supprimée. Les cantiques eux-mêmes restent dans le recueil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await HymnListService.delete(list.id);
    if (mounted) Navigator.pop(context);
  }

  void _play(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HymnListPlayerScreen(
          listName: _list?.name ?? '',
          hymns: _hymns,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final list = _list;

    return Scaffold(
      appBar: AppBar(
        title: Text(list?.name ?? 'Liste de cantiques'),
        actions: [
          if (list != null)
            PopupMenuButton<String>(
              tooltip: 'Options de la liste',
              onSelected: (value) => value == 'rename' ? _rename() : _delete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Renommer')),
                PopupMenuItem(value: 'delete', child: Text('Supprimer la liste')),
              ],
            ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: list == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addHymns,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                      ),
                    ),
                    if (_hymns.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _play(0),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Commencer'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : list == null
              ? const EmptyState(icon: Icons.error_outline, message: 'Cette liste n\'existe plus.')
              : _hymns.isEmpty
                  ? const EmptyState(
                      icon: Icons.playlist_add,
                      message: 'Cette liste est vide. Touchez « Ajouter » pour y mettre '
                          'des cantiques.',
                    )
                  : ReadingWidthConstraint(
                      maxWidth: 640,
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        buildDefaultDragHandles: false,
                        header: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child: Text(
                            '${hymnCountLabel(_hymns.length)} · faites glisser ≡ pour changer l\'ordre',
                            style: TextStyle(fontSize: 13, color: palette.muted),
                          ),
                        ),
                        itemCount: _hymns.length,
                        onReorderItem: (oldIndex, newIndex) {
                          final numbers = [for (final h in _hymns) h.number];
                          final moved = HymnListCodec.moved(numbers, oldIndex, newIndex);
                          _saveOrder([
                            for (final n in moved) _hymns.firstWhere((h) => h.number == n),
                          ]);
                        },
                        itemBuilder: (context, i) {
                          final hymn = _hymns[i];
                          return Material(
                            key: ValueKey(hymn.number),
                            color: palette.background,
                            child: InkWell(
                              onTap: () => _play(i),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20, right: 4),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      child: Text(
                                        '${i + 1}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: palette.muted,
                                        ),
                                      ),
                                    ),
                                    NumberBadge(hymn.number),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        child: Text(
                                          hymn.title,
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w500,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (hymn.audioUrl != null) const HymnAudioMark(),
                                    IconButton(
                                      tooltip: 'Retirer de la liste',
                                      icon: Icon(Icons.close, color: palette.muted),
                                      onPressed: () => _remove(hymn),
                                    ),
                                    ReorderableDragStartListener(
                                      index: i,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.drag_handle,
                                          color: palette.muted,
                                          semanticLabel: 'Déplacer',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
