import 'package:flutter/material.dart';
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
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existing == null ? 'Nouvelle entrée' : 'Modifier l\'entrée',
              style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Pour quoi êtes-vous reconnaissant aujourd\'hui ? '
                    'Quelle est votre prière ?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('Enregistrer'),
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
    await _repo.remove(entry.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Journal de prière')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Aucune entrée pour l\'instant. Touchez + pour noter une prière ou un motif de reconnaissance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.outline),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _entries.length,
                  itemBuilder: (context, i) {
                    final entry = _entries[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _openEditor(existing: entry),
                        title: Text(entry.content, maxLines: 4, overflow: TextOverflow.ellipsis),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(entry.entryDate, style: TextStyle(fontSize: 12, color: scheme.outline)),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(entry),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
