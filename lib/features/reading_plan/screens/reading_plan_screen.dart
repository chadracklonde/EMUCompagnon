import '../../../core/l10n/tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../bible/screens/chapter_screen.dart';
import '../services/reading_plan_service.dart';
import '../../../shared/bible_book_names.dart';

/// "45 min", "1 h 05", "10 h 35" — reading time for a number of verses.
String formatReadingTime(int verses) {
  final minutes = ReadingPlanBuilder.estimatedMinutes(verses);
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}

String _daysLabel(BuildContext context, int days) =>
    days == 1 ? context.tr('rp_days_1') : context.trf('rp_days_n', {'n': days});

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
      // The chapter may have been marked as read from its last line.
      await _load();
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
        title: Text(context.tr('rp_reset_q')),
        content: Text(context.tr('rp_reset_body')),
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
            child: Text(context.tr('rp_reset')),
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
        title: Text(context.tr('rp_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: context.tr('rp_reset'),
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
                                          context.trf('rp_plan_on', {'days': _daysLabel(context, plan.days.length)}),
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w600,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          context.trf('rp_avg', {
                                            'n': plan.averageVersesPerDay,
                                            'time': formatReadingTime(plan.averageVersesPerDay),
                                          }),
                                          style: TextStyle(fontSize: 12.5, color: palette.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: _changeDuration,
                                    child: Text(context.tr('rp_change')),
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
                                    context.trf('rp_next', {'n': nextDay.number, 'label': nextDay.label}),
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
                                    context.tr('rp_done'),
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
                semanticLabel: context.trf('rp_day_read', {'n': day.number}),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.trf('rp_day_line', {'n': day.number, 'v': day.verses}),
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
                    context.trf('rp_day', {'n': day.number}),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.trf('rp_day_detail', {
                      'c': day.chapters.length,
                      'v': day.verses,
                      'time': formatReadingTime(day.verses),
                    }),
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
                            semanticLabel: '${context.bookName(chapter.book)} ${chapter.chapter} lu',
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${context.bookName(chapter.book)} ${chapter.chapter}',
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
    (7, 'rp_week'),
    (30, 'rp_month1'),
    (90, 'rp_months3'),
    (180, 'rp_months6'),
    (365, 'rp_year'),
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
        context.tr('rp_pick'),
        style: TextStyle(fontSize: 13.5, color: palette.muted),
      );
    } else if (!_valid) {
      preview = Text(
        days < 1
            ? context.tr('rp_min1')
            : context.trf('rp_max', {'days': _daysLabel(context, _maxDays), 'n': _maxDays}),
        style: TextStyle(fontSize: 13.5, color: scheme.error),
      );
    } else {
      final perDay = (totalVerses / days).round();
      final plan = ReadingPlanBuilder.split(widget.remaining, days);
      preview = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.trf('rp_per_day', {'n': perDay}),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.trf('rp_read_time', {'time': formatReadingTime(perDay)}),
            style: TextStyle(fontSize: 13.5, color: palette.muted),
          ),
          const SizedBox(height: 8),
          Text(
            context.trf('rp_day1', {'label': plan.first.label}),
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
              context.tr('rp_duration'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.hasProgress
                  ? context.tr('rp_ask_rest')
                  : context.tr('rp_ask_all'),
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
                      label: Text(context.tr(label)),
                      selected: days == presetDays,
                      onSelected: (_) => _select(presetDays),
                    ),
                ChoiceChip(
                  label: Text(context.tr('rp_one_chapter')),
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
              decoration: InputDecoration(
                hintText: context.tr('rp_days_hint'),
                suffixText: context.tr('rp_days_suffix'),
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
                child: Text(context.tr('rp_apply')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
