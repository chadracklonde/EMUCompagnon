import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../services/reading_plan_service.dart';
import '../../bible/screens/chapter_screen.dart';

class ReadingPlanScreen extends StatefulWidget {
  const ReadingPlanScreen({super.key});

  @override
  State<ReadingPlanScreen> createState() => _ReadingPlanScreenState();
}

class _ReadingPlanScreenState extends State<ReadingPlanScreen> {
  List<PlanDay> _plan = [];
  Set<int> _completed = {};
  bool _loading = true;
  final _scrollController = ScrollController();
  bool _scrolledToNext = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final plan = await ReadingPlanService.getFullPlan();
    final completed = await ReadingPlanService.getCompleted();
    if (mounted) {
      setState(() {
        _plan = plan;
        _completed = completed;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(PlanDay day) async {
    if (_completed.contains(day.index)) {
      await ReadingPlanService.markIncomplete(day.index);
      setState(() => _completed.remove(day.index));
    } else {
      await ReadingPlanService.markComplete(day.index);
      setState(() => _completed.add(day.index));
    }
  }

  Future<void> _resetConfirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Réinitialiser le plan ?'),
        content: const Text('Toute la progression sera effacée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ReadingPlanService.resetProgress();
      _scrolledToNext = false;
      _load();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openChapter(PlanDay day) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChapterScreen(book: day.book, chapter: day.chapter),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final total = _plan.length;
    final done = _completed.length;
    final progress = total == 0 ? 0.0 : done / total;
    final nextIndex = _plan.indexWhere((d) => !_completed.contains(d.index));
    final nextDay = nextIndex == -1 ? null : _plan[nextIndex];
    // Uniform row height (grows with the text-size setting) so the list
    // can open directly on the next chapter to read.
    final rowExtent = 36 + MediaQuery.textScalerOf(context).scale(28);

    if (!_loading && !_scrolledToNext && nextIndex > 2) {
      _scrolledToNext = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo((nextIndex - 2) * rowExtent);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan de lecture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Réinitialiser',
            onPressed: _resetConfirm,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ReadingWidthConstraint(
              maxWidth: 640,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Un chapitre par jour, de Genèse à Apocalypse.',
                              style: TextStyle(fontSize: 13.5, color: palette.muted),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${(progress * 100).round()} %',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '$done sur $total chapitres lus',
                                    style: TextStyle(fontSize: 13, color: palette.muted),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: palette.field,
                                color: palette.accent,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (nextDay != null)
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => _openChapter(nextDay),
                                  icon: const Icon(Icons.menu_book_outlined),
                                  label: Text('Continuer — ${nextDay.book} ${nextDay.chapter}'),
                                ),
                              )
                            else
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: palette.accent),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Plan terminé — bravo !',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: palette.accent,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemExtent: rowExtent,
                      itemCount: _plan.length,
                      itemBuilder: (context, i) {
                        final day = _plan[i];
                        return _PlanRow(
                          day: day,
                          isDone: _completed.contains(day.index),
                          isNext: i == nextIndex,
                          onToggle: () => _toggle(day),
                          onOpen: () => _openChapter(day),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final PlanDay day;
  final bool isDone;
  final bool isNext;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  const _PlanRow({
    required this.day,
    required this.isDone,
    required this.isNext,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isNext ? palette.accentSoft : Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 12),
          child: Row(
            children: [
              Checkbox(
                value: isDone,
                onChanged: (_) => onToggle(),
                shape: const CircleBorder(),
                semanticLabel: 'Jour ${day.index + 1} lu',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jour ${day.index + 1}',
                      maxLines: 1,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                    Text(
                      '${day.book} ${day.chapter}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? palette.muted : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: palette.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
