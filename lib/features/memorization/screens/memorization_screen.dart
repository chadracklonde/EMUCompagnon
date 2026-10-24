import 'package:flutter/material.dart';
import '../../../core/models/memory_card.dart';
import '../../bible/repository/bible_repository.dart';
import '../repository/memory_card_repository.dart';

/// Verse-memorization deck: add verses, review the ones due today with a
/// simple spaced-repetition flow, see what's coming up. Entirely offline
/// (local SQLite table), part of the daily-engagement set alongside the
/// reading plan, the streak and the daily quiz.
class MemorizationScreen extends StatefulWidget {
  const MemorizationScreen({super.key});

  @override
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends State<MemorizationScreen> {
  final _repo = MemoryCardRepository();
  List<MemoryCard> _dueToday = [];
  List<MemoryCard> _all = [];
  bool _loading = true;

  // Review-mode state
  bool _reviewing = false;
  int _reviewIndex = 0;
  bool _revealed = false;
  int _reviewedCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final due = await _repo.getDueToday();
    final all = await _repo.getAll();
    if (!mounted) return;
    setState(() {
      _dueToday = due;
      _all = all;
      _loading = false;
    });
  }

  void _startReview() {
    setState(() {
      _reviewing = true;
      _reviewIndex = 0;
      _revealed = false;
      _reviewedCount = 0;
    });
  }

  Future<void> _grade(RecallQuality quality) async {
    final card = _dueToday[_reviewIndex];
    await _repo.grade(card, quality);
    _reviewedCount++;
    if (_reviewIndex + 1 < _dueToday.length) {
      setState(() {
        _reviewIndex++;
        _revealed = false;
      });
    } else {
      setState(() => _reviewing = false);
      await _load();
    }
  }

  Future<void> _removeCard(MemoryCard card) async {
    await _repo.removeCard(card.id);
    await _load();
  }

  Future<void> _addVerseDialog() async {
    final bookNotifier = ValueNotifier<String>(BibleRepository.books.first);
    final chapterController = TextEditingController(text: '1');
    final verseController = TextEditingController(text: '1');
    String? error;

    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Ajouter un verset à mémoriser'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: bookNotifier,
                builder: (_, value, __) => DropdownButtonFormField<String>(
                  value: value,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Livre'),
                  items: BibleRepository.books
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) bookNotifier.value = v;
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: chapterController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Chapitre'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: verseController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Verset'),
                    ),
                  ),
                ],
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final chapter = int.tryParse(chapterController.text.trim());
                final verse = int.tryParse(verseController.text.trim());
                if (chapter == null || verse == null) {
                  setDialogState(() => error = 'Chapitre et verset doivent être des nombres.');
                  return;
                }
                final v = await BibleRepository().getVerse(bookNotifier.value, chapter, verse);
                if (v == null) {
                  setDialogState(() => error = 'Verset introuvable.');
                  return;
                }
                final already = await MemoryCardRepository()
                    .isAlreadyAdded(bookNotifier.value, chapter, verse);
                if (already) {
                  setDialogState(() => error = 'Ce verset est déjà dans votre deck.');
                  return;
                }
                await MemoryCardRepository().addCard(
                  book: bookNotifier.value,
                  chapter: chapter,
                  verse: verse,
                  verseText: v.text,
                  referenceLabel: v.reference,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );

    if (added == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mémorisation'),
        actions: [
          if (!_reviewing)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Ajouter un verset',
              onPressed: _addVerseDialog,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reviewing
              ? _buildReview()
              : _buildOverview(),
    );
  }

  Widget _buildOverview() {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Material(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dueToday.isEmpty
                      ? 'Rien à réviser aujourd\'hui 🎉'
                      : '${_dueToday.length} verset(s) à réviser aujourd\'hui',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                if (_dueToday.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _startReview,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Réviser maintenant'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Mon deck (${_all.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_all.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Ajoutez un verset avec le bouton + en haut, ou depuis le menu d\'un verset dans la Bible.',
              style: TextStyle(color: scheme.outline),
            ),
          )
        else
          ..._all.map((card) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(card.referenceLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Prochaine révision : ${card.dueDate}',
                    style: TextStyle(fontSize: 12, color: scheme.outline),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeCard(card),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildReview() {
    final scheme = Theme.of(context).colorScheme;
    final card = _dueToday[_reviewIndex];
    final progress = (_reviewIndex) / _dueToday.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, minHeight: 6),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.referenceLabel,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  if (!_revealed)
                    OutlinedButton(
                      onPressed: () => setState(() => _revealed = true),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Text('Afficher le texte'),
                      ),
                    )
                  else
                    Text(
                      card.verseText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_revealed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                const Text('Comment avez-vous retenu ce verset ?', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _grade(RecallQuality.again),
                        child: const Text('Encore', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _grade(RecallQuality.hard),
                        child: const Text('Difficile', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _grade(RecallQuality.good),
                        child: const Text('Bien', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => _grade(RecallQuality.easy),
                        child: const Text('Facile', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
