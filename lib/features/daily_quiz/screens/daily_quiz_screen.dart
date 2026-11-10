import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../models/quiz_question.dart';
import '../services/daily_quiz_service.dart';

/// A short, offline, multiple-choice quiz drawn from the biblical/UMC
/// dictionary — one of the daily-engagement building blocks alongside the
/// reading plan and the visit streak.
class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key});

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  List<QuizQuestion> _questions = [];
  bool _loading = true;
  int _current = 0;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;
  bool _alreadyDoneToday = false;
  DailyQuizResult? _priorResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final priorResult = await DailyQuizService.getTodayResult();
    final questions = await DailyQuizService.getTodayQuiz();
    if (!mounted) return;
    setState(() {
      _questions = questions;
      _priorResult = priorResult;
      _alreadyDoneToday = priorResult != null;
      _loading = false;
    });
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == _questions[_current].correctOptionIndex) _score++;
    });
  }

  Future<void> _next() async {
    if (_current + 1 < _questions.length) {
      setState(() {
        _current++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      await DailyQuizService.saveTodayResult(_score, _questions.length);
      if (!mounted) return;
      // _answered must be reset too: the "done" screen is only shown when
      // (_alreadyDoneToday && !_answered) — leaving _answered at its
      // post-last-question value of true kept the result screen from
      // ever appearing.
      setState(() {
        _alreadyDoneToday = true;
        _answered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz du jour')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const EmptyState(
                  icon: Icons.quiz_outlined,
                  message: "Le quiz du jour n'est pas disponible pour le moment.",
                )
              : ReadingWidthConstraint(
                  maxWidth: 640,
                  child: (_alreadyDoneToday && !_answered) ? _buildDoneState() : _buildQuestion(),
                ),
    );
  }

  Widget _buildDoneState() {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final result = _priorResult ?? DailyQuizResult(score: _score, total: _questions.length);
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
              '${result.score} / ${result.total}',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Quiz d'aujourd'hui terminé",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revenez demain pour un nouveau quiz.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Right/wrong keep their conventional green/red, always doubled by an icon.
    final success = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final failure = scheme.error;
    final question = _questions[_current];
    final progress = (_current + 1) / _questions.length;

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
                    value: progress,
                    minHeight: 6,
                    backgroundColor: palette.field,
                    color: palette.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_current + 1} / ${_questions.length}',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quelle est la définition de',
                  style: TextStyle(fontSize: 14, color: palette.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  question.term,
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 22),
                ...List.generate(question.options.length, (i) {
                  final isCorrect = i == question.correctOptionIndex;
                  final isSelected = i == _selectedOption;
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
                        onTap: _answered ? null : () => _selectOption(i),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    question.options[i],
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.4,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (icon != null) ...[
                                  const SizedBox(width: 10),
                                  Icon(icon, color: iconColor, size: 22),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
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
                  child: Text(_current + 1 < _questions.length ? 'Suivant' : 'Terminer'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
