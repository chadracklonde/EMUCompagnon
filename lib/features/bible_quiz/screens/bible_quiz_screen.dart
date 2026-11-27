import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../models/bible_quiz_question.dart';
import '../services/bible_quiz_service.dart';

enum _Phase { setup, playing, result }

/// Offline Bible quiz drawn from the bundled French question bank.
///
/// Setup (Testament / difficulty) → ten questions with instant feedback and
/// the Louis Segond reference when there is one → score and best score.
class BibleQuizScreen extends StatefulWidget {
  /// Overrides the asset bundle (tests).
  final AssetBundle? bundle;
  const BibleQuizScreen({super.key, this.bundle});

  @override
  State<BibleQuizScreen> createState() => _BibleQuizScreenState();
}

class _BibleQuizScreenState extends State<BibleQuizScreen> {
  List<BibleQuizQuestion> _all = [];
  List<BibleQuizQuestion> _session = [];
  bool _loading = true;
  bool _failed = false;
  _Phase _phase = _Phase.setup;
  String? _testament;
  int? _level;
  int _current = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _emptyChoice = false;
  BibleQuizStats _stats = const BibleQuizStats();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await BibleQuizService.loadAll(bundle: widget.bundle);
      final stats = await BibleQuizService.loadStats();
      if (!mounted) return;
      setState(() {
        _all = all;
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    final seen = await BibleQuizService.loadSeen();
    final session = BibleQuizService.pick(
      _all,
      testament: _testament,
      level: _level,
      seen: seen,
    );
    if (!mounted) return;
    if (session.isEmpty) {
      setState(() => _emptyChoice = true);
      return;
    }
    setState(() {
      _session = session;
      _current = 0;
      _score = 0;
      _selected = null;
      _answered = false;
      _emptyChoice = false;
      _phase = _Phase.playing;
    });
  }

  void _select(int index) {
    if (_answered) return;
    setState(() {
      _selected = index;
      _answered = true;
      if (index == _session[_current].correctIndex) _score++;
    });
  }

  Future<void> _next() async {
    if (_current + 1 < _session.length) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
      return;
    }
    await BibleQuizService.markSeen(_session.map((q) => q.id));
    final stats = await BibleQuizService.recordResult(_score, _session.length);
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _phase = _Phase.result;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppSettings>().locale;
    String t(String k) => AppStrings.t(k, locale);
    return Scaffold(
      appBar: AppBar(title: Text(t('bible_quiz'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed || _all.isEmpty
              ? EmptyState(icon: Icons.quiz_outlined, message: t('bq_unavailable'))
              : ReadingWidthConstraint(
                  maxWidth: 640,
                  child: switch (_phase) {
                    _Phase.setup => _buildSetup(locale),
                    _Phase.playing => _buildQuestion(locale),
                    _Phase.result => _buildResult(locale),
                  },
                ),
    );
  }

  Widget _chips<T>({
    required List<(T, String)> items,
    required T selected,
    required void Function(T) onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in items)
          ChoiceChip(
            label: Text(label),
            selected: value == selected,
            onSelected: (_) => onSelect(value),
          ),
      ],
    );
  }

  Widget _buildSetup(String locale) {
    String t(String k) => AppStrings.t(k, locale);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(t('bq_intro'), style: TextStyle(fontSize: 15, height: 1.5, color: scheme.onSurface)),
        const SizedBox(height: 6),
        Text(
          '${AppStrings.tf('bible_quiz_subtitle', locale, {'n': _all.length})} · ${t('bq_french_only')}',
          style: TextStyle(fontSize: 13, color: palette.muted),
        ),
        const SizedBox(height: 24),
        SectionTitle(t('bq_testament')),
        _chips<String?>(
          items: [(null, t('bq_all')), ('AT', t('bq_ot')), ('NT', t('bq_nt'))],
          selected: _testament,
          onSelect: (v) => setState(() => _testament = v),
        ),
        const SizedBox(height: 20),
        SectionTitle(t('bq_level')),
        _chips<int?>(
          items: [
            (null, t('bq_all')),
            (1, t('bq_level_1')),
            (2, t('bq_level_2')),
            (3, t('bq_level_3')),
          ],
          selected: _level,
          onSelect: (v) => setState(() => _level = v),
        ),
        if (_emptyChoice) ...[
          const SizedBox(height: 16),
          Text(t('bq_empty'), style: TextStyle(color: scheme.error)),
        ],
        if (_stats.gamesPlayed > 0) ...[
          const SizedBox(height: 16),
          Text(
            AppStrings.tf('bq_best', locale, {'p': _stats.bestScorePercent}),
            style: TextStyle(fontSize: 13, color: palette.muted),
          ),
        ],
        const SizedBox(height: 28),
        FilledButton(onPressed: _start, child: Text(t('bq_start'))),
      ],
    );
  }

  Widget _buildResult(String locale) {
    String t(String k) => AppStrings.t(k, locale);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.emoji_events_outlined, size: 36, color: palette.accent),
            ),
            const SizedBox(height: 20),
            Text(
              '$_score / ${_session.length}',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: scheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(t('bq_result'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: scheme.onSurface)),
            const SizedBox(height: 8),
            Text(
              AppStrings.tf('bq_best', locale, {'p': _stats.bestScorePercent}),
              style: TextStyle(fontSize: 14, color: palette.muted),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _start, child: Text(t('bq_replay'))),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _phase = _Phase.setup),
              child: Text(t('bq_back')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(String locale) {
    String t(String k) => AppStrings.t(k, locale);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final success = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final failure = scheme.error;
    final question = _session[_current];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_current + 1) / _session.length,
                    minHeight: 6,
                    backgroundColor: palette.field,
                    color: palette.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${_current + 1} / ${_session.length}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.muted)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.text,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 22),
                ...List.generate(question.options.length, (i) {
                  final isCorrect = i == question.correctIndex;
                  final isSelected = i == _selected;
                  Color background = palette.card;
                  Color border = palette.border;
                  IconData? icon;
                  Color? iconColor;
                  if (_answered && isCorrect) {
                    background = success.withValues(alpha: 0.12);
                    border = success;
                    icon = Icons.check_circle;
                    iconColor = success;
                  } else if (_answered && isSelected) {
                    background = failure.withValues(alpha: 0.10);
                    border = failure;
                    icon = Icons.cancel;
                    iconColor = failure;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: border, width: _answered && icon != null ? 1.5 : 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _answered ? null : () => _select(i),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(question.options[i],
                                      style: TextStyle(fontSize: 15, height: 1.4, color: scheme.onSurface)),
                                ),
                                if (icon != null) ...[
                                  const SizedBox(width: 10),
                                  Icon(icon,
                                      color: iconColor,
                                      size: 22,
                                      semanticLabel: isCorrect ? t('bq_correct') : t('bq_wrong')),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                if (_answered && question.references.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.tf('bq_reference', locale, {'r': question.references.join(' ; ')}),
                    style: TextStyle(fontSize: 13, color: palette.muted),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_answered)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_current + 1 < _session.length ? t('bq_next') : t('bq_finish')),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
