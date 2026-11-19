/// Pure planning logic for the reading plan — no database, no storage, so
/// it can be unit-tested on its own.
library;

/// One chapter of the Bible, at its position in the whole-Bible sequence.
class PlanChapter {
  /// 0-based position in the whole Bible (Genesis 1 = 0 … Revelation 22).
  /// This is also the value stored when the chapter is marked as read.
  final int index;
  final String book;
  final int chapter;
  final int verses;

  const PlanChapter({
    required this.index,
    required this.book,
    required this.chapter,
    required this.verses,
  });
}

/// One day of reading: one or more chapters, always whole chapters.
class ReadingDay {
  /// 1-based day number within the plan.
  final int number;
  final List<PlanChapter> chapters;

  const ReadingDay({required this.number, required this.chapters});

  int get verses => chapters.fold(0, (sum, c) => sum + c.verses);

  /// "Genèse 1–12", "Genèse 49–50 · Exode 1–9", or "Genèse 1–3, 5" when
  /// already-read chapters left gaps.
  String get label {
    final parts = <String>[];
    var i = 0;
    while (i < chapters.length) {
      final book = chapters[i].book;
      final ranges = <String>[];
      while (i < chapters.length && chapters[i].book == book) {
        final start = chapters[i];
        var end = start;
        while (i + 1 < chapters.length &&
            chapters[i + 1].book == book &&
            chapters[i + 1].index == chapters[i].index + 1) {
          i++;
          end = chapters[i];
        }
        ranges.add(
          start.chapter == end.chapter ? '${start.chapter}' : '${start.chapter}–${end.chapter}',
        );
        i++;
      }
      parts.add('$book ${ranges.join(', ')}');
    }
    return parts.join(' · ');
  }
}

class ReadingPlanBuilder {
  /// Rough silent-reading pace used for the "about N minutes a day" hint.
  static const int versesPerMinute = 7;

  static int estimatedMinutes(int verses) => (verses / versesPerMinute).ceil();

  /// Splits [chapters] (in reading order) into [days] consecutive days of
  /// roughly equal length, measured in verses, cutting only between
  /// chapters.
  ///
  /// Each day gets at least one chapter, so the result has
  /// `min(days, chapters.length)` days: a plan cannot be longer than one
  /// chapter per day.
  static List<ReadingDay> split(List<PlanChapter> chapters, int days) {
    if (chapters.isEmpty || days < 1) return const [];
    final dayCount = days > chapters.length ? chapters.length : days;

    // cumulative[i] = verses in chapters[0..i).
    final cumulative = List<int>.filled(chapters.length + 1, 0);
    for (var i = 0; i < chapters.length; i++) {
      cumulative[i + 1] = cumulative[i] + chapters[i].verses;
    }
    final total = cumulative.last;

    final result = <ReadingDay>[];
    var start = 0;
    for (var day = 1; day <= dayCount; day++) {
      int end; // exclusive
      if (day == dayCount) {
        end = chapters.length;
      } else {
        // Where the running total should stand at the end of this day.
        final target = total * day / dayCount;
        // Leave at least one chapter for each remaining day.
        final maxEnd = chapters.length - (dayCount - day);
        end = start + 1;
        while (end < maxEnd &&
            (cumulative[end + 1] - target).abs() <= (cumulative[end] - target).abs()) {
          end++;
        }
      }
      result.add(ReadingDay(number: day, chapters: chapters.sublist(start, end)));
      start = end;
    }
    return result;
  }
}
