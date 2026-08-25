import 'package:flutter_test/flutter_test.dart';
import 'package:emu_compagnon/features/liturgy/services/easter_calculator.dart';

void main() {
  group('EasterCalculator', () {
    // Known official Easter Sunday dates, used to validate the algorithm.
    final knownDates = {
      2024: DateTime(2024, 3, 31),
      2025: DateTime(2025, 4, 20),
      2026: DateTime(2026, 4, 5),
      2027: DateTime(2027, 3, 28),
      2030: DateTime(2030, 4, 21),
    };

    knownDates.forEach((year, expected) {
      test('computes Easter $year correctly', () {
        final result = EasterCalculator.calculate(year);
        expect(result, expected);
      });
    });

    test('Easter always falls on a Sunday', () {
      for (var year = 2020; year <= 2035; year++) {
        final date = EasterCalculator.calculate(year);
        expect(date.weekday, DateTime.sunday, reason: 'Year $year');
      }
    });
  });
}
