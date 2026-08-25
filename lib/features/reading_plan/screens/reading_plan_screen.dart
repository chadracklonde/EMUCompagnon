import 'package:flutter/material.dart';
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
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Réinitialiser')),
        ],
      ),
    );
    if (confirmed == true) {
      await ReadingPlanService.resetProgress();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = _plan.length;
    final done = _completed.length;
    final progress = total == 0 ? 0.0 : done / total;
    final nextDay = _plan.firstWhere(
      (d) => !_completed.contains(d.index),
      orElse: () => _plan.isNotEmpty ? _plan.last : const PlanDay(index: 0, book: '', chapter: 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan de lecture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Réinitialiser',
            onPressed: _resetConfirm,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Un chapitre par jour, de Genèse à Apocalypse.',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('$done / $total chapitres lus (${(progress * 100).round()} %)',
                          style: TextStyle(fontSize: 12, color: scheme.outline)),
                      if (done < total) ...[
                        const SizedBox(height: 12),
                        Material(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ChapterScreen(book: nextDay.book, chapter: nextDay.chapter),
                            )),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(Icons.play_circle_outline, color: scheme.onPrimaryContainer),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Continuer — ${nextDay.book} ${nextDay.chapter}',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text('🎉 Plan terminé — bravo !', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _plan.length,
                    itemBuilder: (context, i) {
                      final day = _plan[i];
                      final isDone = _completed.contains(day.index);
                      return CheckboxListTile(
                        value: isDone,
                        onChanged: (_) => _toggle(day),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'Jour ${day.index + 1} — ${day.book} ${day.chapter}',
                          style: TextStyle(
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            color: isDone ? scheme.outline : null,
                          ),
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ChapterScreen(book: day.book, chapter: day.chapter),
                          )),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
