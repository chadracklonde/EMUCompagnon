import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dictionary/repository/dictionary_repository.dart';
import '../models/quiz_question.dart';

class DailyQuizResult {
  final int score;
  final int total;
  const DailyQuizResult({required this.score, required this.total});
}

/// Builds a short multiple-choice quiz from the bundled biblical/UMC
/// dictionary ("which definition matches this term?").
///
/// The quiz is deterministic for a given calendar day — same date seed,
/// same questions — so reopening it later the same day shows the same
/// quiz rather than a fresh random draw, and today's score is remembered
/// locally (SharedPreferences, like the reading plan and the streak).
/// Entirely offline: it only reads from the bundled dictionary table.
class DailyQuizService {
  static const int questionsPerDay = 5;
  static const _kResultPrefix = 'dailyQuiz.result.';

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _seedForDate(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static Future<List<QuizQuestion>> getTodayQuiz() async {
    final repo = DictionaryRepository();
    final ids = await repo.getAllIds();

    final rng = Random(_seedForDate(DateTime.now()));
    final shuffled = List<int>.from(ids)..shuffle(rng);
    final questionCount = min(questionsPerDay, shuffled.length);
    if (questionCount == 0) return [];

    final correctIds = shuffled.take(questionCount).toList();
    final pool = shuffled.skip(questionCount).toList();

    // Fetch the correct entries plus a generous slice of the remaining
    // pool to draw distractors from (3 per question, with some slack for
    // skipped near-duplicate definitions).
    final entries = await repo.getByIds([
      ...correctIds,
      ...pool.take(questionCount * 6),
    ]);
    final byId = {for (final e in entries) e.id: e};

    final questions = <QuizQuestion>[];
    var poolIndex = 0;
    for (final id in correctIds) {
      final entry = byId[id];
      if (entry == null) continue;

      final distractors = <String>[];
      while (distractors.length < 3 && poolIndex < pool.length) {
        final candidate = byId[pool[poolIndex]];
        poolIndex++;
        if (candidate != null &&
            candidate.definition != entry.definition &&
            !distractors.contains(candidate.definition)) {
          distractors.add(candidate.definition);
        }
      }
      if (distractors.length < 3) continue; // not enough material, skip

      final options = [entry.definition, ...distractors]..shuffle(rng);
      questions.add(QuizQuestion(
        term: entry.term,
        options: options,
        correctOptionIndex: options.indexOf(entry.definition),
      ));
    }
    return questions;
  }

  static Future<DailyQuizResult?> getTodayResult() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_kResultPrefix${_dateKey(DateTime.now())}');
    if (raw == null) return null;
    final parts = raw.split('/');
    if (parts.length != 2) return null;
    final score = int.tryParse(parts[0]);
    final total = int.tryParse(parts[1]);
    if (score == null || total == null) return null;
    return DailyQuizResult(score: score, total: total);
  }

  static Future<void> saveTodayResult(int score, int total) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_kResultPrefix${_dateKey(DateTime.now())}',
      '$score/$total',
    );
  }
}
