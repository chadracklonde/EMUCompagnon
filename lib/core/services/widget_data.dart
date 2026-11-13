/// Pure helpers that shape what the home-screen widgets show. The values
/// are plain text and numbers, written by [WidgetSyncService] and drawn by
/// the native widgets (native/android/).
class WidgetData {
  static const _months = [
    '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  static const _shortMonths = [
    '', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];
  static const _weekdays = [
    '', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche',
  ];

  /// "2026-11-11", the key under which a day's entry is stored.
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// "dimanche 15 novembre".
  static String longDate(DateTime d) => '${_weekdays[d.weekday]} ${d.day} ${_months[d.month]}';

  /// "15 nov.".
  static String shortDate(DateTime d) => '${d.day} ${_shortMonths[d.month]}';

  /// Cuts [text] to about [max] characters at a word end, with "…".
  static String truncate(String text, int max) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean;
    final cut = clean.substring(0, max);
    final space = cut.lastIndexOf(' ');
    final base = space > max ~/ 2 ? cut.substring(0, space) : cut;
    return '${base.replaceAll(RegExp(r'[\s,;:.]+$'), '')}…';
  }

  /// "1 jour", "3 jours".
  static String plural(int n, String one, String many) => '$n ${n > 1 ? many : one}';

  /// "Aujourd'hui", "Demain", "42 jours".
  static String countdownTitle(int days) {
    if (days <= 0) return "Aujourd'hui";
    if (days == 1) return 'Demain';
    return '$days jours';
  }

  /// The item of [items] for [day]: a different one each day, in turn.
  static T pickByDay<T>(List<T> items, DateTime day) {
    final dayOfYear = dayOnly(day).difference(DateTime(day.year, 1, 1)).inDays;
    return items[dayOfYear % items.length];
  }

  /// The seven days of the week of [today], Monday first: 1 for a day the
  /// app was opened in the current streak, 0 otherwise. The streak is
  /// consecutive days ending on [lastActive], so that is all it takes.
  static List<int> weekDots({
    required DateTime today,
    required DateTime? lastActive,
    required int streak,
  }) {
    final monday = dayOnly(today).subtract(Duration(days: today.weekday - 1));
    return [
      for (var i = 0; i < 7; i++)
        if (lastActive != null && streak > 0 && _inStreak(monday.add(Duration(days: i)), lastActive, streak)) 1 else 0,
    ];
  }

  static bool _inStreak(DateTime day, DateTime lastActive, int streak) {
    final last = dayOnly(lastActive);
    final first = last.subtract(Duration(days: streak - 1));
    return !day.isBefore(first) && !day.isAfter(last);
  }

  /// One entry per day for the next [days] days, for widgets whose content
  /// changes daily: the widget picks today's, so it stays right without the
  /// app being opened.
  static Map<String, dynamic> daily(
    DateTime from,
    int days,
    Map<String, dynamic> Function(DateTime day) entry,
  ) =>
      {
        'days': {
          for (var i = 0; i < days; i++)
            dayKey(DateTime(from.year, from.month, from.day + i)):
                entry(DateTime(from.year, from.month, from.day + i)),
        },
      };
}
