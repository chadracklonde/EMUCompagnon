import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/hymn_list_service.dart';

const _months = [
  '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// "Culte du 15 novembre" — the coming Sunday (today if it is Sunday),
/// the most likely thing a new list is for.
String suggestedListName([DateTime? now]) {
  final today = now ?? DateTime.now();
  final sunday = today.add(Duration(days: (DateTime.sunday - today.weekday) % 7));
  final day = sunday.day == 1 ? '1er' : '${sunday.day}';
  return 'Culte du $day ${_months[sunday.month]}';
}

/// Asks for a list name. Returns null when cancelled.
Future<String?> askListName(
  BuildContext context, {
  required String title,
  required String initial,
  String confirmLabel = 'Enregistrer',
}) {
  final controller = TextEditingController(text: initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: initial.length);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final name = controller.text.trim();
        void submit() {
          if (name.isNotEmpty) Navigator.pop(dialogContext, name);
        }

        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Nom de la liste', counterText: ''),
            onChanged: (_) => setDialogState(() {}),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(onPressed: name.isEmpty ? null : submit, child: Text(confirmLabel)),
          ],
        );
      },
    ),
  );
}

String hymnCountLabel(int count) =>
    count == 0 ? 'Aucun cantique' : count == 1 ? '1 cantique' : '$count cantiques';

/// Bottom sheet shown from a hymn: pick the list to add it to, or create
/// one. Returns the name of the list it was added to, or null.
Future<void> showAddToListSheet(
  BuildContext context, {
  required String number,
  required String title,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await showModalBottomSheet<({String name, bool added})>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddToListSheet(number: number),
  );
  if (result == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(
        result.added
            ? 'N° $number ajouté à « ${result.name} ».'
            : 'N° $number est déjà dans « ${result.name} ».',
      ),
    ));
}

class _AddToListSheet extends StatefulWidget {
  final String number;
  const _AddToListSheet({required this.number});

  @override
  State<_AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends State<_AddToListSheet> {
  List<HymnList>? _lists;

  @override
  void initState() {
    super.initState();
    HymnListService.getAll().then((lists) {
      if (mounted) setState(() => _lists = lists);
    });
  }

  Future<void> _addTo(HymnList list) async {
    final added = await HymnListService.addHymn(list.id, widget.number);
    if (mounted) Navigator.pop(context, (name: list.name, added: added));
  }

  Future<void> _createAndAdd() async {
    final name = await askListName(
      context,
      title: 'Nouvelle liste',
      initial: suggestedListName(),
      confirmLabel: 'Créer',
    );
    if (name == null) return;
    final list = await HymnListService.create(name, numbers: [widget.number]);
    if (mounted) Navigator.pop(context, (name: list.name, added: true));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lists = _lists;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Ajouter le n° ${widget.number} à une liste',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            if (lists == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final list in lists)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        leading: Icon(
                          list.numbers.contains(widget.number)
                              ? Icons.check_circle
                              : Icons.queue_music,
                        ),
                        title: Text(list.name),
                        subtitle: Text(
                          list.numbers.contains(widget.number)
                              ? 'Déjà dans cette liste'
                              : hymnCountLabel(list.numbers.length),
                          style: TextStyle(fontSize: 12.5, color: palette.muted),
                        ),
                        onTap: () => _addTo(list),
                      ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: const Icon(Icons.add),
                      title: const Text('Nouvelle liste…'),
                      onTap: _createAndAdd,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
