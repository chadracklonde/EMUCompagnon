import 'package:shared_preferences/shared_preferences.dart';
import '../../bible/repository/bible_repository.dart';

class PlanDay {
  final int index; // 0-based position in the whole-Bible sequence
  final String book;
  final int chapter;
  const PlanDay({required this.index, required this.book, required this.chapter});
}

/// A simple "one chapter a day, straight through the whole Bible" reading
/// plan (Genesis 1 → Revelation 22, ~1189 days). Progress is tracked as a
/// set of completed day-indices rather than tied to calendar dates, so
/// falling behind never creates a guilt-inducing "you're 12 days late"
/// message — the user just checks off what they've read, whenever.
class ReadingPlanService {
  static const _kCompletedIndices = 'readingPlan.completedIndices';

  static List<PlanDay>? _cachedPlan;

  static Future<List<PlanDay>> getFullPlan() async {
    if (_cachedPlan != null) return _cachedPlan!;
    final repo = BibleRepository();
    final days = <PlanDay>[];
    var index = 0;
    for (final book in BibleRepository.books) {
      final count = await repo.chapterCount(book);
      for (var ch = 1; ch <= count; ch++) {
        days.add(PlanDay(index: index, book: book, chapter: ch));
        index++;
      }
    }
    _cachedPlan = days;
    return days;
  }

  static Future<Set<int>> getCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCompletedIndices);
    if (raw == null || raw.isEmpty) return {};
    return raw.split(',').map(int.parse).toSet();
  }

  static Future<void> _saveCompleted(Set<int> completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCompletedIndices, completed.join(','));
  }

  static Future<void> markComplete(int index) async {
    final completed = await getCompleted();
    completed.add(index);
    await _saveCompleted(completed);
  }

  static Future<void> markIncomplete(int index) async {
    final completed = await getCompleted();
    completed.remove(index);
    await _saveCompleted(completed);
  }

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCompletedIndices);
  }

  /// The first not-yet-completed day, i.e. where to resume.
  static Future<PlanDay?> getNextDay() async {
    final plan = await getFullPlan();
    final completed = await getCompleted();
    for (final day in plan) {
      if (!completed.contains(day.index)) return day;
    }
    return null; // whole plan completed
  }
}
