import 'package:flutter_test/flutter_test.dart';
import 'package:emu_compagnon/features/backup/services/backup_merge.dart';

void main() {
  group('mergeReadingPlan', () {
    test('union of both lists, sorted, without duplicates', () {
      expect(mergeReadingPlan('0,1,5', '1,2,9'), '0,1,2,5,9');
    });
    test('one side empty or null', () {
      expect(mergeReadingPlan(null, '3,4'), '3,4');
      expect(mergeReadingPlan('7', ''), '7');
    });
    test('both empty gives null', () {
      expect(mergeReadingPlan(null, null), isNull);
      expect(mergeReadingPlan('', ''), isNull);
    });
    test('ignores malformed entries', () {
      expect(mergeReadingPlan('1,x,,-3', '2, 4'), '1,2,4');
    });
  });

  group('mergeStreak', () {
    test('keeps the most recent side for the current streak', () {
      final merged = mergeStreak(
        const StreakState(lastDate: '2026-10-20', current: 3, longest: 10),
        const StreakState(lastDate: '2026-10-28', current: 5, longest: 6),
      );
      expect(merged, const StreakState(lastDate: '2026-10-28', current: 5, longest: 10));
    });
    test('local is more recent: local current kept', () {
      final merged = mergeStreak(
        const StreakState(lastDate: '2026-10-29', current: 2, longest: 2),
        const StreakState(lastDate: '2026-10-01', current: 9, longest: 9),
      );
      expect(merged, const StreakState(lastDate: '2026-10-29', current: 2, longest: 9));
    });
    test('same day on both sides: larger current wins', () {
      final merged = mergeStreak(
        const StreakState(lastDate: '2026-10-29', current: 4, longest: 4),
        const StreakState(lastDate: '2026-10-29', current: 7, longest: 7),
      );
      expect(merged, const StreakState(lastDate: '2026-10-29', current: 7, longest: 7));
    });
    test('fresh install (no local date) takes the imported streak', () {
      final merged = mergeStreak(
        const StreakState(),
        const StreakState(lastDate: '2026-10-25', current: 12, longest: 20),
      );
      expect(merged, const StreakState(lastDate: '2026-10-25', current: 12, longest: 20));
    });
    test('importing nothing changes nothing', () {
      const local = StreakState(lastDate: '2026-10-25', current: 3, longest: 8);
      expect(mergeStreak(local, const StreakState()), local);
    });
    test('longest is never lower than current', () {
      final merged = mergeStreak(
        const StreakState(lastDate: '2026-10-25', current: 5, longest: 1),
        const StreakState(),
      );
      expect(merged.longest, 5);
    });
  });
}
