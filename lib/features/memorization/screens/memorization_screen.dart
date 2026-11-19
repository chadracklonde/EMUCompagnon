import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
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
    });
  }

  Future<void> _grade(RecallQuality quality) async {
    final card = _dueToday[_reviewIndex];
    await _repo.grade(card, quality);
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
                  key: ValueKey(value),
                  initialValue: value,
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
              const SizedBox(height: 12),
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
                  child: Text(
                    error!,
                    style: TextStyle(color: Theme.of(dialogContext).colorScheme.error, fontSize: 12.5),
                  ),
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
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dueCount = _dueToday.length;

    return ReadingWidthConstraint(
      maxWidth: 640,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: palette.accentSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          dueCount == 0 ? Icons.check : Icons.psychology_outlined,
                          color: palette.accent,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dueCount == 0
                              ? "Rien à réviser aujourd'hui"
                              : dueCount == 1
                                  ? "1 verset à réviser aujourd'hui"
                                  : "$dueCount versets à réviser aujourd'hui",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dueCount > 0) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _startReview,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Réviser maintenant'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle('Mes versets (${_all.length})'),
          if (_all.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: EmptyState(
                icon: Icons.bookmark_add_outlined,
                message: "Ajoutez un verset avec le bouton + en haut, ou depuis les "
                    "actions d'un verset dans la Bible.",
              ),
            )
          else
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < _all.length; i++) ...[
                    if (i > 0) Divider(indent: 16, color: palette.border),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _all[i].referenceLabel,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Prochaine révision : ${_all[i].dueDate}',
                                  style: TextStyle(fontSize: 12.5, color: palette.muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Retirer ce verset',
                            icon: Icon(Icons.delete_outline, color: palette.muted),
                            onPressed: () => _removeCard(_all[i]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReview() {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final card = _dueToday[_reviewIndex];
    final progress = _reviewIndex / _dueToday.length;

    Widget gradeButton(String label, RecallQuality quality, {bool primary = false}) {
      final child = Text(label, maxLines: 1, style: const TextStyle(fontSize: 13));
      final style = ButtonStyle(
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 4)),
      );
      return Expanded(
        child: primary
            ? FilledButton(onPressed: () => _grade(quality), style: style, child: child)
            : OutlinedButton(onPressed: () => _grade(quality), style: style, child: child),
      );
    }

    return ReadingWidthConstraint(
      maxWidth: 640,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: palette.field,
                      color: palette.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_reviewIndex + 1} / ${_dueToday.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            card.referenceLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: palette.accent,
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (!_revealed)
                            OutlinedButton.icon(
                              onPressed: () => setState(() => _revealed = true),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Afficher le texte'),
                            )
                          else
                            Text(
                              card.verseText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 19,
                                height: 1.5,
                                color: scheme.onSurface,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_revealed)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  children: [
                    Text(
                      'Comment avez-vous retenu ce verset ?',
                      style: TextStyle(fontSize: 13, color: palette.muted),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        gradeButton('Encore', RecallQuality.again),
                        const SizedBox(width: 8),
                        gradeButton('Difficile', RecallQuality.hard),
                        const SizedBox(width: 8),
                        gradeButton('Bien', RecallQuality.good, primary: true),
                        const SizedBox(width: 8),
                        gradeButton('Facile', RecallQuality.easy),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
