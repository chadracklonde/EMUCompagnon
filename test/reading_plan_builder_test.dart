import 'package:flutter_test/flutter_test.dart';
import 'package:emu_compagnon/features/reading_plan/services/reading_plan_builder.dart';

/// Builds chapters from `{book: [verses per chapter]}`.
List<PlanChapter> chaptersOf(Map<String, List<int>> books) {
  final chapters = <PlanChapter>[];
  books.forEach((book, verses) {
    for (var i = 0; i < verses.length; i++) {
      chapters.add(PlanChapter(
        index: chapters.length,
        book: book,
        chapter: i + 1,
        verses: verses[i],
      ));
    }
  });
  return chapters;
}

void main() {
  group('ReadingPlanBuilder.split', () {
    test('covers every chapter exactly once, in order', () {
      final chapters = chaptersOf({
        'A': [10, 20, 30, 5, 5],
        'B': [40, 1, 1, 60],
      });
      for (var days = 1; days <= chapters.length; days++) {
        final plan = ReadingPlanBuilder.split(chapters, days);
        expect(plan.length, days);
        expect(plan.expand((d) => d.chapters).map((c) => c.index), [0, 1, 2, 3, 4, 5, 6, 7, 8]);
        expect(plan.every((d) => d.chapters.isNotEmpty), isTrue);
        expect(plan.map((d) => d.number), List.generate(days, (i) => i + 1));
      }
    });

    test('balances days by verses, not by number of chapters', () {
      // 100 verses then ten chapters of 10: two days should be 100 / 100.
      final chapters = chaptersOf({
        'A': [100, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10],
      });
      final plan = ReadingPlanBuilder.split(chapters, 2);
      expect(plan.map((d) => d.verses), [100, 100]);
      expect(plan.first.chapters.length, 1);
    });

    test('equal chapters split evenly', () {
      final chapters = chaptersOf({'A': List.filled(12, 25)});
      final plan = ReadingPlanBuilder.split(chapters, 4);
      expect(plan.map((d) => d.chapters.length), [3, 3, 3, 3]);
    });

    test('never plans more days than there are chapters', () {
      final chapters = chaptersOf({'A': [10, 10, 10]});
      final plan = ReadingPlanBuilder.split(chapters, 30);
      expect(plan.length, 3);
      expect(plan.every((d) => d.chapters.length == 1), isTrue);
    });

    test('one day holds everything; no chapters or no days give no plan', () {
      final chapters = chaptersOf({'A': [10, 20], 'B': [30]});
      expect(ReadingPlanBuilder.split(chapters, 1).single.verses, 60);
      expect(ReadingPlanBuilder.split(const [], 5), isEmpty);
      expect(ReadingPlanBuilder.split(chapters, 0), isEmpty);
    });
  });

  group('ReadingDay.label', () {
    test('names a range inside one book and across books', () {
      final chapters = chaptersOf({'Genèse': [1, 1, 1], 'Exode': [1, 1]});
      expect(ReadingDay(number: 1, chapters: chapters.sublist(0, 3)).label, 'Genèse 1–3');
      expect(ReadingDay(number: 1, chapters: chapters.sublist(1, 2)).label, 'Genèse 2');
      expect(ReadingDay(number: 1, chapters: chapters.sublist(2)).label, 'Genèse 3 · Exode 1–2');
    });

    test('shows gaps left by chapters already read', () {
      final chapters = chaptersOf({'Genèse': [1, 1, 1, 1, 1]});
      final withGap = [chapters[0], chapters[1], chapters[3]];
      expect(ReadingDay(number: 1, chapters: withGap).label, 'Genèse 1–2, 4');
    });
  });

  test('reading time rounds up to whole minutes', () {
    expect(ReadingPlanBuilder.estimatedMinutes(7), 1);
    expect(ReadingPlanBuilder.estimatedMinutes(8), 2);
    expect(ReadingPlanBuilder.estimatedMinutes(0), 0);
  });
}
