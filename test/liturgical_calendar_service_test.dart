import 'package:flutter_test/flutter_test.dart';
import 'package:emu_compagnon/features/liturgy/services/liturgical_calendar_service.dart';
import 'package:emu_compagnon/features/liturgy/models/liturgical_period.dart';

void main() {
  group('LiturgicalCalendarService', () {
    test('periodsForChurchYear returns exactly 10 periods (6 seasons + 4 holy days)', () {
      final periods = LiturgicalCalendarService.periodsForChurchYear(2025);
      expect(periods.length, 10);
      expect(
        periods.where((p) => p.period.type == LiturgicalPeriodType.season).length,
        6,
      );
      expect(
        periods.where((p) => p.period.type == LiturgicalPeriodType.holyDay).length,
        4,
      );
    });

    test('Advent Sunday 2025 falls on Nov 30', () {
      final periods = LiturgicalCalendarService.periodsForChurchYear(2025);
      final advent = periods.firstWhere((p) => p.period.id == 'avent');
      expect(advent.start, DateTime(2025, 11, 30));
    });

    test('Christmas is always December 25', () {
      final periods = LiturgicalCalendarService.periodsForChurchYear(2025);
      final christmas = periods.firstWhere((p) => p.period.id == 'noel');
      expect(christmas.start, DateTime(2025, 12, 25));
    });

    test('churchYearStartFor correctly resolves a date in early January', () {
      // Jan 2, 2026 is still within the church year that started Advent 2025.
      final churchYear = LiturgicalCalendarService.churchYearStartFor(DateTime(2026, 1, 2));
      expect(churchYear, 2025);
    });

    test('churchYearStartFor correctly resolves a date in December after Advent', () {
      final churchYear = LiturgicalCalendarService.churchYearStartFor(DateTime(2025, 12, 5));
      expect(churchYear, 2025);
    });

    test('all periods in a church year are chronologically ordered with valid ranges', () {
      final periods = LiturgicalCalendarService.periodsForChurchYear(2025);
      for (final p in periods) {
        expect(p.start.isBefore(p.end) || p.start.isAtSameMomentAs(p.end), true,
            reason: '${p.period.id}: start must not be after end');
      }
      // Chronological order across the whole list (start dates non-decreasing).
      for (var i = 0; i < periods.length - 1; i++) {
        expect(
          !periods[i + 1].start.isBefore(periods[i].start),
          true,
          reason: '${periods[i].period.id} should not start after ${periods[i + 1].period.id}',
        );
      }
      // The whole church year (Advent to the eve of the next Advent) is
      // exactly covered day-by-day by the union of all periods — built by
      // direct enumeration (not a formula) so it can't be thrown off by
      // the intentional overlaps between a holy day and its season
      // (Christmas/Easter) versus the holy days that don't overlap any
      // season (Epiphany, Pentecost).
      final coveredDays = <DateTime>{};
      for (final p in periods) {
        for (var d = p.start; !d.isAfter(p.end); d = d.add(const Duration(days: 1))) {
          coveredDays.add(DateTime(d.year, d.month, d.day));
        }
      }
      final firstDay = periods.map((p) => p.start).reduce((a, b) => a.isBefore(b) ? a : b);
      final lastDay = periods.map((p) => p.end).reduce((a, b) => a.isAfter(b) ? a : b);
      final totalSpanDays = lastDay.difference(firstDay).inDays + 1;
      expect(coveredDays.length, totalSpanDays,
          reason: 'Every calendar day of the church year should be covered by exactly one season (holy days may overlap a season\'s first day)');
    });
  });
}
