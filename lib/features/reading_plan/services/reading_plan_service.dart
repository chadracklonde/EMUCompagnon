import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/db_helper.dart';
import 'reading_plan_builder.dart';
import 'reading_reminder.dart';

export 'reading_plan_builder.dart';

/// The plan as it stands now: the chosen duration, its days, and progress.
class ReadingPlan {
  /// Every chapter of the Bible, in order.
  final List<PlanChapter> allChapters;

  /// Chapters already read when the current duration was chosen. They are
  /// not scheduled again: the plan only spreads what was left to read.
  final Set<int> baseline;

  /// Everything read so far (includes [baseline]).
  final Set<int> completed;

  /// The days of the plan, covering every chapter outside [baseline].
  final List<ReadingDay> days;

  const ReadingPlan({
    required this.allChapters,
    required this.baseline,
    required this.completed,
    required this.days,
  });

  int get totalChapters => allChapters.length;
  int get readChapters => completed.length;
  double get progress => totalChapters == 0 ? 0 : readChapters / totalChapters;

  bool isDayDone(ReadingDay day) => day.chapters.every((c) => completed.contains(c.index));

  /// Index in [days] of the first day not fully read, or -1 when finished.
  int get nextDayIndex => days.indexWhere((d) => !isDayDone(d));

  ReadingDay? get nextDay => nextDayIndex == -1 ? null : days[nextDayIndex];

  /// The first unread chapter of [day] (or its first chapter when all read).
  PlanChapter firstUnread(ReadingDay day) => day.chapters.firstWhere(
        (c) => !completed.contains(c.index),
        orElse: () => day.chapters.first,
      );

  /// Verses per day, averaged over the planned days.
  int get averageVersesPerDay {
    if (days.isEmpty) return 0;
    final verses = days.fold(0, (sum, d) => sum + d.verses);
    return (verses / days.length).round();
  }
}

/// Whole-Bible reading plan over a number of days chosen by the user.
///
/// Progress is a set of read chapter indices rather than calendar dates, so
/// falling behind never creates a guilt-inducing "you're 12 days late"
/// message — the user just checks off what they've read, whenever.
///
/// The duration defaults to one chapter a day (1189 days), which is what
/// the plan always was before the duration became adjustable. Choosing
/// another duration keeps what has been read and spreads only the rest,
/// balanced by number of verses and always cut at chapter ends.
class ReadingPlanService {
  static const _kCompletedIndices = 'readingPlan.completedIndices';
  static const _kDurationDays = 'readingPlan.durationDays';
  static const _kBaselineIndices = 'readingPlan.baselineIndices';
  static const _version = 'LSG1910';

  static List<PlanChapter>? _cachedChapters;

  /// All chapters with their verse counts, from a single query.
  static Future<List<PlanChapter>> getChapters() async {
    if (_cachedChapters != null) return _cachedChapters!;
    final db = await DbHelper.database;
    final rows = await db.rawQuery(
      'SELECT book, chapter, COUNT(*) AS verses FROM bible_verses '
      'WHERE version = ? GROUP BY book_num, chapter ORDER BY book_num, chapter',
      [_version],
    );
    final chapters = <PlanChapter>[
      for (var i = 0; i < rows.length; i++)
        PlanChapter(
          index: i,
          book: rows[i]['book'] as String,
          chapter: rows[i]['chapter'] as int,
          verses: rows[i]['verses'] as int,
        ),
    ];
    _cachedChapters = chapters;
    return chapters;
  }

  static Set<int> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    return raw.split(',').map(int.tryParse).whereType<int>().toSet();
  }

  static Future<Set<int>> getCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_kCompletedIndices));
  }

  static Future<void> _saveCompleted(Set<int> completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCompletedIndices, completed.join(','));
  }

  /// Builds the current plan from the stored duration and progress.
  static Future<ReadingPlan> getPlan() async {
    final chapters = await getChapters();
    final prefs = await SharedPreferences.getInstance();
    final completed = _decode(prefs.getString(_kCompletedIndices));
    final baseline = _decode(prefs.getString(_kBaselineIndices));
    final scheduled = chapters.where((c) => !baseline.contains(c.index)).toList();
    final duration = prefs.getInt(_kDurationDays) ?? scheduled.length;
    return ReadingPlan(
      allChapters: chapters,
      baseline: baseline,
      completed: completed,
      days: ReadingPlanBuilder.split(scheduled, duration),
    );
  }

  /// Chooses a new duration: what is already read is kept, and only the
  /// remaining chapters are spread over [days].
  static Future<void> setDuration(int days) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = _decode(prefs.getString(_kCompletedIndices));
    await prefs.setInt(_kDurationDays, days);
    await prefs.setString(_kBaselineIndices, completed.join(','));
    await ReadingReminder.sync();
  }

  /// Position of [book] [chapter] in the whole Bible, or null if unknown.
  static Future<int?> indexOf(String book, int chapter) async {
    final chapters = await getChapters();
    for (final c in chapters) {
      if (c.book == book && c.chapter == chapter) return c.index;
    }
    return null;
  }

  static Future<void> setChapterRead(int index, bool read) async {
    final completed = await getCompleted();
    read ? completed.add(index) : completed.remove(index);
    await _saveCompleted(completed);
    await ReadingReminder.sync();
  }

  static Future<void> setDayRead(ReadingDay day, bool read) async {
    final completed = await getCompleted();
    final indices = day.chapters.map((c) => c.index);
    read ? completed.addAll(indices) : completed.removeAll(indices);
    await _saveCompleted(completed);
    await ReadingReminder.sync();
  }

  /// Clears all progress. The chosen duration is kept and now applies to
  /// the whole Bible again.
  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCompletedIndices);
    await prefs.remove(_kBaselineIndices);
    await ReadingReminder.sync();
  }
}
