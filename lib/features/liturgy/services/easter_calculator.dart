/// Computes the date of (Western/Gregorian) Easter Sunday for a given year,
/// using the Meeus/Jones/Butcher algorithm. All other moveable feasts
/// (Ash Wednesday, Pentecost, Ascension...) are derived as fixed offsets
/// from this date.
class EasterCalculator {
  static DateTime calculate(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final monthDayValue = h + l - 7 * m + 114;
    final month = monthDayValue ~/ 31;
    final day = (monthDayValue % 31) + 1;
    return DateTime(year, month, day);
  }
}
