import 'package:flutter/material.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz du jour')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Le quiz du jour n\'est pas disponible pour le moment.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : (_alreadyDoneToday && !_answered)
                  ? _buildDoneState(scheme)
                  : _buildQuestion(scheme),
    );
  }

  Widget _buildDoneState(ColorScheme scheme) {
    final result = _priorResult ?? DailyQuizResult(score: _score, total: _questions.length);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 56, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'Quiz déjà fait aujourd\'hui',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Score : ${result.score} / ${result.total}',
              style: TextStyle(fontSize: 16, color: scheme.outline),
            ),
            const SizedBox(height: 8),
            Text(
              'Reviens demain pour un nouveau quiz.',
              style: TextStyle(fontSize: 13, color: scheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(ColorScheme scheme) {
    final question = _questions[_current];
    final progress = (_current + 1) / _questions.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Question ${_current + 1} / ${_questions.length}',
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quelle est la définition de :',
                  style: TextStyle(fontSize: 13, color: scheme.outline),
                ),
                const SizedBox(height: 6),
                Text(
                  question.term,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                ),
                const SizedBox(height: 20),
                ...List.generate(question.options.length, (i) {
                  final isCorrect = i == question.correctOptionIndex;
                  final isSelected = i == _selectedOption;
                  Color? bg;
                  Color? border = scheme.outlineVariant;
                  if (_answered) {
                    if (isCorrect) {
                      bg = Colors.green.withValues(alpha: 0.15);
                      border = Colors.green;
                    } else if (isSelected) {
                      bg = Colors.red.withValues(alpha: 0.12);
                      border = Colors.red;
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: bg ?? scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _selectOption(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(question.options[i])),
                              if (_answered && isCorrect)
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              if (_answered && isSelected && !isCorrect)
                                const Icon(Icons.cancel, color: Colors.red, size: 20),
                            ],
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(_current + 1 < _questions.length ? 'Suivant' : 'Terminer'),
              ),
            ),
          ),
      ],
    );
  }
}
