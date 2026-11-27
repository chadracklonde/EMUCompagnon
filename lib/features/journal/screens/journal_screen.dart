import '../../../core/l10n/tr.dart';
import 'package:flutter/material.dart';
import '../../help/screens/help_button.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../core/models/journal_entry.dart';
import '../repository/journal_repository.dart';

/// Private prayer/gratitude journal — a free-text entry per day, kept
/// entirely on-device. Part of the daily-engagement set.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _repo = JournalRepository();
  List<JournalEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await _repo.getAll();
    if (mounted) setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _openEditor({JournalEntry? existing}) async {
    final controller = TextEditingController(text: existing?.content ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(existing == null ? 'jr_new' : 'jr_edit'),
              style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: context.tr('jr_hint'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: Text(context.tr('save')),
              ),
            ),
          ],
        ),
      ),
    );

    final text = controller.text.trim();
    if (saved == true && text.isNotEmpty) {
      if (existing == null) {
        await _repo.add(text);
      } else {
        await _repo.update(existing.id, text);
      }
      await _load();
    }
  }

  Future<void> _delete(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('jr_delete_q')),
        content: Text(context.tr('jr_delete_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.remove(entry.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('jr_title')),
        actions: const [HelpButton('journal'), SizedBox(width: 4)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.edit_outlined),
        label: Text(context.tr('jr_new')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? EmptyState(
                  icon: Icons.edit_note_outlined,
                  message: context.tr('jr_empty'),
                )
              : ReadingWidthConstraint(
                  maxWidth: 640,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final entry = _entries[i];
                      return AppCard(
                        onTap: () => _openEditor(existing: entry),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 4, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.entryDate,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: palette.accent,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: context.tr('delete'),
                                    icon: Icon(Icons.delete_outline, color: palette.muted),
                                    onPressed: () => _delete(entry),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                  entry.content,
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
