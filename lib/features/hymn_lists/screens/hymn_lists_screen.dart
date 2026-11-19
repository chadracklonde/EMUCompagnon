import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../services/hymn_list_service.dart';
import '../widgets/list_dialogs.dart';
import 'hymn_list_detail_screen.dart';

/// The user's hymn lists (service programmes): create one, open one.
class HymnListsScreen extends StatefulWidget {
  const HymnListsScreen({super.key});

  @override
  State<HymnListsScreen> createState() => _HymnListsScreenState();
}

class _HymnListsScreenState extends State<HymnListsScreen> {
  List<HymnList>? _lists;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lists = await HymnListService.getAll();
    if (mounted) setState(() => _lists = lists);
  }

  Future<void> _open(HymnList list) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HymnListDetailScreen(listId: list.id)),
    );
    await _load();
  }

  Future<void> _create() async {
    final name = await askListName(
      context,
      title: 'Nouvelle liste',
      initial: suggestedListName(),
      confirmLabel: 'Créer',
    );
    if (name == null) return;
    final list = await HymnListService.create(name);
    if (mounted) await _open(list);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final lists = _lists;
    return Scaffold(
      appBar: AppBar(title: const Text('Listes de cantiques')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle liste'),
      ),
      body: lists == null
          ? const Center(child: CircularProgressIndicator())
          : lists.isEmpty
              ? const EmptyState(
                  icon: Icons.queue_music,
                  message: 'Préparez les chants d\'un culte ou d\'une répétition : créez une '
                      'liste, ajoutez-y des cantiques, puis enchaînez-les dans l\'ordre.',
                )
              : ReadingWidthConstraint(
                  maxWidth: 640,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                    children: [
                      AppCard(
                        child: Column(
                          children: [
                            for (var i = 0; i < lists.length; i++) ...[
                              if (i > 0) Divider(indent: 64, color: palette.border),
                              AppRow(
                                icon: Icons.queue_music,
                                title: lists[i].name,
                                subtitle: hymnCountLabel(lists[i].numbers.length),
                                onTap: () => _open(lists[i]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
