import 'package:flutter/material.dart';
import '../../../core/models/bookmark.dart';
import '../../../core/models/note.dart';
import '../repository/notes_repository.dart';

/// Opens a bottom sheet listing existing notes for [type]/[refId] and
/// letting the user add a new one or edit/delete existing ones.
/// [label] is shown as a header (e.g. "Jean 3.16").
Future<void> showNotesSheet(
  BuildContext context, {
  required BookmarkType type,
  required int refId,
  required String label,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _NotesSheet(type: type, refId: refId, label: label),
  );
}

class _NotesSheet extends StatefulWidget {
  final BookmarkType type;
  final int refId;
  final String label;
  const _NotesSheet({required this.type, required this.refId, required this.label});

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  final _repo = NotesRepository();
  final _controller = TextEditingController();
  List<VerseNote> _notes = [];
  int? _editingId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await _repo.listFor(widget.type, widget.refId);
    if (mounted) {
      setState(() {
        _notes = notes;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_editingId != null) {
      await _repo.update(_editingId!, text);
    } else {
      await _repo.add(widget.type, widget.refId, text);
    }
    _controller.clear();
    _editingId = null;
    await _load();
  }

  void _startEdit(VerseNote note) {
    setState(() {
      _editingId = note.id;
      _controller.text = note.noteText;
    });
  }

  Future<void> _delete(VerseNote note) async {
    await _repo.delete(note.id);
    if (_editingId == note.id) {
      _editingId = null;
      _controller.clear();
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sticky_note_2_outlined,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Notes — ${widget.label}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_notes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucune note pour l\'instant.',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _notes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final n = _notes[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(n.noteText),
                    subtitle: Text(_formatDate(n.updatedAt)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _startEdit(n),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _delete(n),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _editingId != null
                  ? 'Modifier la note…'
                  : 'Écrire une note personnelle…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: Icon(_editingId != null ? Icons.check : Icons.add),
              label: Text(_editingId != null ? 'Mettre à jour' : 'Ajouter'),
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return "Aujourd'hui à ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    }
    return '${d.day}/${d.month}/${d.year}';
  }
}
