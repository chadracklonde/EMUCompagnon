import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../bible/screens/chapter_screen.dart';
import '../services/reading_plan_service.dart';

/// "45 min", "1 h 05", "10 h 35" — reading time for a number of verses.
String formatReadingTime(int verses) {
  final minutes = ReadingPlanBuilder.estimatedMinutes(verses);
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}

String _daysLabel(int days) => days == 1 ? '1 jour' : '$days jours';

class ReadingPlanScreen extends StatefulWidget {
  const ReadingPlanScreen({super.key});

  @override
  State<ReadingPlanScreen> createState() => _ReadingPlanScreenState();
}

class _ReadingPlanScreenState extends State<ReadingPlanScreen> {
  ReadingPlan? _plan;
  final _scrollController = ScrollController();
  bool _scrolledToNext = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final plan = await ReadingPlanService.getPlan();
    if (mounted) setState(() => _plan = plan);
  }

  Future<void> _toggleDay(ReadingDay day) async {
    final plan = _plan!;
    await ReadingPlanService.setDayRead(day, !plan.isDayDone(day));
    await _load();
  }

  Future<void> _openChapter(PlanChapter chapter) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChapterScreen(book: chapter.book, chapter: chapter.chapter),
    ));
  }

  /// A one-chapter day opens that chapter directly; a longer day first
  /// shows its chapters, each with its own "read" box.
  Future<void> _openDay(ReadingDay day) async {
    if (day.chapters.length == 1) {
      await _openChapter(day.chapters.first);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DaySheet(day: day, onOpenChapter: _openChapter),
    );
    await _load();
  }

  Future<void> _changeDuration() async {
    final plan = _plan!;
    final remaining =
        plan.allChapters.where((c) => !plan.completed.contains(c.index)).toList();
    if (remaining.isEmpty) return;
    final days = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DurationSheet(
        remaining: remaining,
        hasProgress: plan.completed.isNotEmpty,
      ),
    );
    if (days == null) return;
    await ReadingPlanService.setDuration(days);
    _scrolledToNext = false;
    await _load();
  }

  Future<void> _resetConfirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Réinitialiser le plan ?'),
        content: const Text(
          'Toute la progression sera effacée. La durée choisie est conservée '
          'et repart du début de la Bible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ReadingPlanService.resetProgress();
      _scrolledToNext = false;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Uniform row height (grows with the text-size setting) so the list
    // can open directly on the next day to read.
    final rowExtent = 40 + MediaQuery.textScalerOf(context).scale(30);

    final nextIndex = plan?.nextDayIndex ?? -1;
    final nextDay = plan?.nextDay;

    if (plan != null && !_scrolledToNext) {
      _scrolledToNext = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final target = nextIndex > 1 ? (nextIndex - 1) * rowExtent : 0.0;
        _scrollController.jumpTo(
          target.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan de lecture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Réinitialiser',
            onPressed: plan == null ? null : _resetConfirm,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: plan == null
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${(plan.progress * 100).round()} %',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '${plan.readChapters} sur ${plan.totalChapters} chapitres lus',
                                      style: TextStyle(fontSize: 13, color: palette.muted),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: plan.progress,
                                minHeight: 6,
                                backgroundColor: palette.field,
                                color: palette.accent,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (nextDay != null) ...[
                              // The chosen pace, and the way to change it.
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Plan sur ${_daysLabel(plan.days.length)}',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w600,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Environ ${plan.averageVersesPerDay} versets par jour '
                                          '(${formatReadingTime(plan.averageVersesPerDay)})',
                                          style: TextStyle(fontSize: 12.5, color: palette.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: _changeDuration,
                                    child: const Text('Changer'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    await _openDay(nextDay);
                                  },
                                  icon: const Icon(Icons.menu_book_outlined),
                                  label: Text(
                                    'Jour ${nextDay.number} — ${nextDay.label}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ] else
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
                      itemCount: plan.days.length,
                      itemBuilder: (context, i) {
                        final day = plan.days[i];
                        return _DayRow(
                          day: day,
                          isDone: plan.isDayDone(day),
                          isNext: i == nextIndex,
                          onToggle: () => _toggleDay(day),
                          onOpen: () => _openDay(day),
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

class _DayRow extends StatelessWidget {
  final ReadingDay day;
  final bool isDone;
  final bool isNext;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  const _DayRow({
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
                semanticLabel: 'Jour ${day.number} lu',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jour ${day.number} · ${day.verses} versets',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                    Text(
                      day.label,
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

/// The chapters of one day: tap one to read it, tick it when read.
class _DaySheet extends StatefulWidget {
  final ReadingDay day;
  final Future<void> Function(PlanChapter) onOpenChapter;
  const _DaySheet({required this.day, required this.onOpenChapter});

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  Set<int> _completed = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final completed = await ReadingPlanService.getCompleted();
    if (mounted) setState(() => _completed = completed);
  }

  Future<void> _toggle(PlanChapter chapter) async {
    await ReadingPlanService.setChapterRead(chapter.index, !_completed.contains(chapter.index));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final day = widget.day;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jour ${day.number}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.chapters.length} chapitres · ${day.verses} versets · '
                    'environ ${formatReadingTime(day.verses)}',
                    style: TextStyle(fontSize: 13, color: palette.muted),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: day.chapters.length,
                itemBuilder: (context, i) {
                  final chapter = day.chapters[i];
                  final isRead = _completed.contains(chapter.index);
                  return InkWell(
                    onTap: () async {
                      await widget.onOpenChapter(chapter);
                      await _refresh();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 16),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isRead,
                            onChanged: (_) => _toggle(chapter),
                            shape: const CircleBorder(),
                            semanticLabel: '${chapter.book} ${chapter.chapter} lu',
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${chapter.book} ${chapter.chapter}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                decoration: isRead ? TextDecoration.lineThrough : null,
                                color: isRead ? palette.muted : scheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            '${chapter.verses} v.',
                            style: TextStyle(fontSize: 12.5, color: palette.muted),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.chevron_right, color: palette.muted, size: 22),
                        ],
                      ),
                    ),
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

/// Lets the user pick over how many days to read what is left: presets or
/// any number, with a live preview of the daily amount.
class _DurationSheet extends StatefulWidget {
  /// Chapters still to read; only these are spread over the new duration.
  final List<PlanChapter> remaining;
  final bool hasProgress;
  const _DurationSheet({
    required this.remaining,
    required this.hasProgress,
  });

  @override
  State<_DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<_DurationSheet> {
  static const _presets = [
    (7, '1 semaine'),
    (30, '1 mois'),
    (90, '3 mois'),
    (180, '6 mois'),
    (365, '1 an'),
  ];

  late final TextEditingController _controller;

  int get _maxDays => widget.remaining.length;
  int? get _days => int.tryParse(_controller.text.trim());
  bool get _valid => _days != null && _days! >= 1 && _days! <= _maxDays;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(int days) {
    final text = '$days';
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final days = _days;
    final totalVerses = widget.remaining.fold(0, (sum, c) => sum + c.verses);

    Widget preview;
    if (days == null) {
      preview = Text(
        'Choisissez une durée ou saisissez un nombre de jours.',
        style: TextStyle(fontSize: 13.5, color: palette.muted),
      );
    } else if (!_valid) {
      preview = Text(
        days < 1
            ? 'Saisissez au moins 1 jour.'
            : 'Au maximum ${_daysLabel(_maxDays)} : il reste $_maxDays chapitres, '
                'soit un chapitre par jour.',
        style: TextStyle(fontSize: 13.5, color: scheme.error),
      );
    } else {
      final perDay = (totalVerses / days).round();
      final plan = ReadingPlanBuilder.split(widget.remaining, days);
      preview = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Environ $perDay versets par jour',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Soit environ ${formatReadingTime(perDay)} de lecture par jour.',
            style: TextStyle(fontSize: 13.5, color: palette.muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Jour 1 : ${plan.first.label}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.5, color: scheme.onSurface),
          ),
        ],
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Durée du plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.hasProgress
                  ? 'En combien de jours voulez-vous lire ce qui reste ? '
                      'Les chapitres déjà lus sont conservés.'
                  : 'En combien de jours voulez-vous lire toute la Bible ?',
              style: TextStyle(fontSize: 13.5, height: 1.4, color: palette.muted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (presetDays, label) in _presets)
                  if (presetDays <= _maxDays)
                    ChoiceChip(
                      label: Text(label),
                      selected: days == presetDays,
                      onSelected: (_) => _select(presetDays),
                    ),
                ChoiceChip(
                  label: const Text('1 chapitre par jour'),
                  selected: days == _maxDays,
                  onSelected: (_) => _select(_maxDays),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                hintText: 'Nombre de jours',
                suffixText: 'jours',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.field,
                borderRadius: BorderRadius.circular(14),
              ),
              child: preview,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _valid ? () => Navigator.pop(context, _days) : null,
                child: const Text('Appliquer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
