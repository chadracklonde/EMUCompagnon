import '../data/liturgical_calendar_data.dart';
import '../models/liturgical_period.dart';
import 'easter_calculator.dart';

/// Computed key dates for one "church year" — the cycle that begins on
/// Advent Sunday of [churchYearStart] (Nov/Dec of that calendar year) and
/// runs through the day before the next Advent Sunday (late Nov of
/// [churchYearStart] + 1).
class _ChurchYearDates {
  final DateTime advent1;
  final DateTime christmas;
  final DateTime epiphany;
  final DateTime ashWednesday;
  final DateTime easter;
  final DateTime pentecost;
  final DateTime nextAdvent1;

  _ChurchYearDates({
    required this.advent1,
    required this.christmas,
    required this.epiphany,
    required this.ashWednesday,
    required this.easter,
    required this.pentecost,
    required this.nextAdvent1,
  });

  factory _ChurchYearDates.forStartYear(int churchYearStart) {
    final christmas = DateTime(churchYearStart, 12, 25);
    final epiphany = DateTime(churchYearStart + 1, 1, 6);
    final easter = EasterCalculator.calculate(churchYearStart + 1);
    return _ChurchYearDates(
      advent1: _adventStart(churchYearStart),
      christmas: christmas,
      epiphany: epiphany,
      ashWednesday: easter.subtract(const Duration(days: 46)),
      easter: easter,
      pentecost: easter.add(const Duration(days: 49)),
      nextAdvent1: _adventStart(churchYearStart + 1),
    );
  }

  /// Advent Sunday: the Sunday nearest November 30, i.e. the 4th Sunday
  /// before Christmas Day.
  static DateTime _adventStart(int year) {
    final christmas = DateTime(year, 12, 25);
    final daysBack = christmas.weekday % 7; // Dart: Mon=1..Sun=7, so Sun%7=0
    final sundayOnOrBeforeChristmas =
        christmas.subtract(Duration(days: daysBack));
    return sundayOnOrBeforeChristmas.subtract(const Duration(days: 21));
  }
}

class LiturgicalCalendarService {
  /// Returns the 10 periods (6 seasons + 4 holy days) with their computed
  /// start/end dates for the church year beginning on Advent Sunday of
  /// [churchYearStart].
  static List<LiturgicalPeriodInstance> periodsForChurchYear(
    int churchYearStart,
  ) {
    final d = _ChurchYearDates.forStartYear(churchYearStart);
    final data = LiturgicalCalendarData.periods;
    LiturgicalPeriod byId(String id) => data.firstWhere((p) => p.id == id);
    DateTime dayBefore(DateTime date) => date.subtract(const Duration(days: 1));

    return [
      LiturgicalPeriodInstance(
        period: byId('avent'),
        start: d.advent1,
        end: dayBefore(d.christmas),
      ),
      LiturgicalPeriodInstance(
        period: byId('noel'),
        start: d.christmas,
        end: d.christmas,
      ),
      LiturgicalPeriodInstance(
        period: byId('temps_noel'),
        start: d.christmas,
        end: dayBefore(d.epiphany),
      ),
      LiturgicalPeriodInstance(
        period: byId('epiphanie'),
        start: d.epiphany,
        end: d.epiphany,
      ),
      LiturgicalPeriodInstance(
        period: byId('ordinaire_epiphanie'),
        start: d.epiphany.add(const Duration(days: 1)),
        end: dayBefore(d.ashWednesday),
      ),
      LiturgicalPeriodInstance(
        period: byId('careme'),
        start: d.ashWednesday,
        end: dayBefore(d.easter),
      ),
      LiturgicalPeriodInstance(
        period: byId('paques'),
        start: d.easter,
        end: d.easter,
      ),
      LiturgicalPeriodInstance(
        period: byId('temps_paques'),
        start: d.easter,
        end: dayBefore(d.pentecost),
      ),
      LiturgicalPeriodInstance(
        period: byId('pentecote'),
        start: d.pentecost,
        end: d.pentecost,
      ),
      LiturgicalPeriodInstance(
        period: byId('ordinaire_pentecote'),
        start: d.pentecost.add(const Duration(days: 1)),
        end: dayBefore(d.nextAdvent1),
      ),
    ];
  }

  /// Determines which calendar year's Advent Sunday starts the church year
  /// that [date] falls within.
  static int churchYearStartFor(DateTime date) {
    final advent1ThisCalendarYear = _ChurchYearDates._adventStart(date.year);
    final today = DateTime(date.year, date.month, date.day);
    if (!today.isBefore(advent1ThisCalendarYear)) {
      return date.year;
    }
    return date.year - 1;
  }

  /// Returns the current season (not a single-day holy day) containing
  /// [date], plus the full list of periods for that church year.
  static (LiturgicalPeriodInstance, List<LiturgicalPeriodInstance>)
      currentSeason([DateTime? date]) {
    final today = date ?? DateTime.now();
    final churchYearStart = churchYearStartFor(today);
    final all = periodsForChurchYear(churchYearStart);
    final seasons =
        all.where((p) => p.period.type == LiturgicalPeriodType.season);
    final current = seasons.firstWhere(
      (p) => p.contains(today),
      orElse: () => seasons.first,
    );
    return (current, all);
  }

  /// Returns the holy day instance matching [date], if [date] is exactly
  /// one of the 4 key holy days.
  static LiturgicalPeriodInstance? holyDayOn(
    DateTime date,
    List<LiturgicalPeriodInstance> periodsThisChurchYear,
  ) {
    final today = DateTime(date.year, date.month, date.day);
    for (final p in periodsThisChurchYear) {
      if (p.period.type == LiturgicalPeriodType.holyDay &&
          DateTime(p.start.year, p.start.month, p.start.day) == today) {
        return p;
      }
    }
    return null;
  }
}
