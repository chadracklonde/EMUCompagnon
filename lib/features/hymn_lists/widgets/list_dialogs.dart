import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_theme.dart';
import '../services/hymn_list_service.dart';

/// "Culte du 15 novembre" — the coming Sunday (today if it is Sunday),
/// the most likely thing a new list is for.
String suggestedListName([DateTime? now, String locale = 'fr']) {
  final today = now ?? DateTime.now();
  final sunday =
      today.add(Duration(days: (DateTime.sunday - today.weekday) % 7));
  final day = locale == 'fr' && sunday.day == 1 ? '1er' : '${sunday.day}';
  final date = '$day ${AppStrings.monthName(sunday.month, locale)}';
  return AppStrings.tf('hl_default_name', locale, {'date': date});
}

/// Asks for a list name. Returns null when cancelled.
Future<String?> askListName(
  BuildContext context, {
  required String title,
  required String initial,
  String? confirmLabel,
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
            decoration: InputDecoration(
                hintText: dialogContext.tr('hl_name'), counterText: ''),
            onChanged: (_) => setDialogState(() {}),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogContext.tr('cancel')),
            ),
            FilledButton(
                onPressed: name.isEmpty ? null : submit,
                child: Text(confirmLabel ?? dialogContext.tr('save'))),
          ],
        );
      },
    ),
  );
}

String hymnCountLabel(BuildContext context, int count) => count == 0
    ? context.tr('hl_count_0')
    : count == 1
        ? context.tr('hl_count_1')
        : context.trf('hl_count_n', {'n': count});

/// Bottom sheet shown from a hymn: pick the list to add it to, or create
/// one. Returns the name of the list it was added to, or null.
Future<void> showAddToListSheet(
  BuildContext context, {
  required String number,
  required String title,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final addedText = context.trf('hl_added', {'n': number, 'name': '{name}'});
  final alreadyText =
      context.trf('hl_already_in', {'n': number, 'name': '{name}'});
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
        (result.added ? addedText : alreadyText)
            .replaceAll('{name}', result.name),
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
      title: context.tr('hl_new'),
      initial: suggestedListName(null, context.lang),
      confirmLabel: context.tr('create'),
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
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                context.trf('hl_add_to', {'n': widget.number}),
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
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        leading: Icon(
                          list.numbers.contains(widget.number)
                              ? Icons.check_circle
                              : Icons.queue_music,
                        ),
                        title: Text(list.name),
                        subtitle: Text(
                          list.numbers.contains(widget.number)
                              ? context.tr('hl_already_this')
                              : hymnCountLabel(context, list.numbers.length),
                          style:
                              TextStyle(fontSize: 12.5, color: palette.muted),
                        ),
                        onTap: () => _addTo(list),
                      ),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      leading: const Icon(Icons.add),
                      title: Text(context.tr('hl_new_dots')),
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
