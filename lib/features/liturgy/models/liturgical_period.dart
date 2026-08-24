enum LiturgicalPeriodType { season, holyDay }

/// One entry of the Christian liturgical calendar (a season or a holy day).
/// Dates are NOT stored here — they are computed per-year by
/// LiturgicalCalendarService, since Easter-based dates move every year.
class LiturgicalPeriod {
  final String id;
  final String name;
  final LiturgicalPeriodType type;
  final String colorName;
  final int colorHex; // ARGB, e.g. 0xFF6A3D9A
  final String summary;
  final String description;

  const LiturgicalPeriod({
    required this.id,
    required this.name,
    required this.type,
    required this.colorName,
    required this.colorHex,
    required this.summary,
    required this.description,
  });
}

/// A period with its computed start/end dates for a specific church year.
class LiturgicalPeriodInstance {
  final LiturgicalPeriod period;
  final DateTime start;
  final DateTime end; // inclusive

  const LiturgicalPeriodInstance({
    required this.period,
    required this.start,
    required this.end,
  });

  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }
}
