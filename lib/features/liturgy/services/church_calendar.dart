import 'easter_calculator.dart';

/// Liturgical colour of a day, as the United Methodist Church uses them
/// (Book of Worship, "Colors for the Christian Year").
class LiturgicalColorInfo {
  final String name;

  /// ARGB, for a swatch.
  final int hex;
  const LiturgicalColorInfo(this.name, this.hex);

  static const purple = LiturgicalColorInfo('Violet', 0xFF5E3A8C);
  static const purpleOrBlue = LiturgicalColorInfo('Violet ou bleu', 0xFF5E3A8C);
  static const holyWeek = LiturgicalColorInfo('Violet (ou rouge en Semaine sainte)', 0xFF5E3A8C);
  static const whiteGold = LiturgicalColorInfo('Blanc ou or', 0xFFD4A017);
  static const white = LiturgicalColorInfo('Blanc', 0xFFFFFFFF);
  static const green = LiturgicalColorInfo('Vert', 0xFF2E7D32);
  static const red = LiturgicalColorInfo('Rouge', 0xFFE4002B);
  static const none = LiturgicalColorInfo('Aucune (dépouillement)', 0xFF8A8580);
}

/// A named season of the Christian year, with the days it runs over.
class ChurchSeasonSpan {
  final String id;
  final String name;
  final DateTime start;

  /// Last day, inclusive.
  final DateTime end;
  final LiturgicalColorInfo color;
  const ChurchSeasonSpan(this.id, this.name, this.start, this.end, this.color);

  bool contains(DateTime d) {
    final day = ChurchCalendar.dayOnly(d);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}

/// A Sunday, a feast or another day of the Christian year.
class ChurchDay {
  final DateTime date;

  /// Stable key, e.g. "advent-1", "easter", "pentecost+3".
  final String id;
  final String name;

  /// Id of the season it belongs to ("avent", "careme"…).
  final String seasonId;
  final LiturgicalColorInfo color;
  final bool isSunday;

  /// A "special Sunday" of the Church (Discipline ¶ 262 to 265), shown
  /// next to the Sunday of the Christian year it falls on.
  final bool isSpecial;

  /// A line or two on what the day is.
  final String? note;

  /// For a special Sunday: how its date is fixed.
  final String? rule;

  const ChurchDay({
    required this.date,
    required this.id,
    required this.name,
    required this.seasonId,
    required this.color,
    this.isSunday = false,
    this.isSpecial = false,
    this.note,
    this.rule,
  });
}

/// The Christian year, computed by rule for any year: Easter (Gregorian
/// computus) fixes Ash Wednesday, Holy Week, Ascension and Pentecost, and
/// Advent fixes the start of the cycle. Nothing is stored per year.
///
/// A "church year" starts on the First Sunday of Advent of [startYear] and
/// ends the day before the First Sunday of Advent of the next year.
class ChurchCalendar {
  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _add(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

  /// First Sunday strictly after [d].
  static DateTime sundayAfter(DateTime d) => _add(d, 7 - d.weekday % 7);

  /// First Sunday on or after [d].
  static DateTime sundayOnOrAfter(DateTime d) => _add(d, (7 - d.weekday) % 7);

  /// Last Sunday strictly before [d].
  static DateTime sundayBefore(DateTime d) => _add(d, -(d.weekday % 7 == 0 ? 7 : d.weekday));

  static DateTime easter(int year) => EasterCalculator.calculate(year);

  /// First Sunday of Advent of [year]: the fourth Sunday before Christmas.
  static DateTime advent1(int year) {
    final christmas = DateTime(year, 12, 25);
    return _add(christmas, -christmas.weekday - 21);
  }

  /// The church year a date belongs to, named by the year of its Advent.
  static int churchYearStartFor(DateTime date) {
    final d = dayOnly(date);
    return !d.isBefore(advent1(d.year)) ? d.year : d.year - 1;
  }

  /// "A", "B" or "C": the cycle of the Revised Common Lectionary. The year
  /// that starts in Advent 2025 is A, 2026 is B, 2027 is C, and so on.
  static String lectionaryYear(int startYear) => const ['A', 'B', 'C'][startYear % 3];

  static String _ordinal(int n) => n == 1 ? '1er' : '${n}e';

  static String _sunday(int n, String after) => '${_ordinal(n)} dimanche $after';

  static final _cache = <int, List<ChurchDay>>{};

  /// Every day of the church year starting in Advent of [startYear], in date
  /// order (several entries may share a date: a special Sunday falls on a
  /// Sunday of the Christian year).
  static List<ChurchDay> churchYear(int startYear, {bool specials = true}) {
    final all = _cache.putIfAbsent(startYear, () => _build(startYear));
    return specials ? all : [for (final d in all) if (!d.isSpecial) d];
  }

  /// All the entries on [date].
  static List<ChurchDay> daysOn(DateTime date, {bool specials = true}) {
    final d = dayOnly(date);
    return [
      for (final day in churchYear(churchYearStartFor(d), specials: specials))
        if (day.date == d) day,
    ];
  }

  /// The main entry on [date] (a feast or Sunday of the Christian year), if any.
  static ChurchDay? dayOn(DateTime date) {
    for (final day in daysOn(date, specials: false)) {
      return day;
    }
    return null;
  }

  /// The seasons of the church year, in order.
  static List<ChurchSeasonSpan> seasons(int startYear) {
    final y = startYear;
    final a1 = advent1(y);
    final nextAdvent = advent1(y + 1);
    final e = easter(y + 1);
    final pentecost = _add(e, 49);
    return [
      ChurchSeasonSpan('avent', 'Avent', a1, DateTime(y, 12, 24), LiturgicalColorInfo.purpleOrBlue),
      ChurchSeasonSpan('temps_noel', 'Temps de Noël', DateTime(y, 12, 25), DateTime(y + 1, 1, 5),
          LiturgicalColorInfo.whiteGold),
      ChurchSeasonSpan('epiphanie', 'Épiphanie', DateTime(y + 1, 1, 6), DateTime(y + 1, 1, 6),
          LiturgicalColorInfo.whiteGold),
      ChurchSeasonSpan('ordinaire_epiphanie', "Temps ordinaire après l'Épiphanie", DateTime(y + 1, 1, 7),
          _add(e, -47), LiturgicalColorInfo.green),
      ChurchSeasonSpan('careme', 'Carême', _add(e, -46), _add(e, -1), LiturgicalColorInfo.holyWeek),
      ChurchSeasonSpan('temps_paques', 'Temps de Pâques', e, _add(pentecost, -1), LiturgicalColorInfo.whiteGold),
      ChurchSeasonSpan('pentecote', 'Dimanche de Pentecôte', pentecost, pentecost, LiturgicalColorInfo.red),
      ChurchSeasonSpan('ordinaire_pentecote', 'Temps ordinaire après la Pentecôte', _add(pentecost, 1),
          _add(nextAdvent, -1), LiturgicalColorInfo.green),
    ];
  }

  /// The season [date] is in.
  static ChurchSeasonSpan seasonOn(DateTime date) {
    final d = dayOnly(date);
    final spans = seasons(churchYearStartFor(d));
    for (final s in spans) {
      if (s.contains(d)) return s;
    }
    return spans.first;
  }

  /// Colour of [date]: that of its feast or Sunday when it has one, else of
  /// its season.
  static LiturgicalColorInfo colorOn(DateTime date) => dayOn(date)?.color ?? seasonOn(date).color;

  /// The Sunday on or after [date], with its name.
  static ChurchDay? nextSunday(DateTime date) {
    final sunday = sundayOnOrAfter(dayOnly(date));
    return dayOn(sunday);
  }

  static List<ChurchDay> _build(int y) {
    final days = <ChurchDay>[];
    void add(DateTime date, String id, String name, String season, LiturgicalColorInfo color,
        {bool sunday = false, bool special = false, String? note, String? rule}) {
      days.add(ChurchDay(
        date: dayOnly(date),
        id: id,
        name: name,
        seasonId: season,
        color: color,
        isSunday: sunday,
        isSpecial: special,
        note: note,
        rule: rule,
      ));
    }

    final a1 = advent1(y);
    final nextAdvent = advent1(y + 1);
    final e = easter(y + 1);
    final ashWednesday = _add(e, -46);
    final pentecost = _add(e, 49);

    // Advent.
    for (var n = 1; n <= 4; n++) {
      add(_add(a1, 7 * (n - 1)), 'advent-$n', _sunday(n, "de l'Avent"), 'avent', LiturgicalColorInfo.purpleOrBlue,
          sunday: true,
          note: n == 1 ? "Premier dimanche de l'année chrétienne : l'Église commence un nouveau cycle." : null);
    }

    // Christmas season.
    add(DateTime(y, 12, 24), 'christmas-eve', 'Veille de Noël', 'avent', LiturgicalColorInfo.whiteGold);
    add(DateTime(y, 12, 25), 'christmas', 'Nativité du Seigneur (Noël)', 'temps_noel', LiturgicalColorInfo.whiteGold,
        sunday: DateTime(y, 12, 25).weekday == DateTime.sunday,
        note: "On célèbre la naissance de Jésus-Christ, la Parole faite chair.");
    final afterChristmas = sundayAfter(DateTime(y, 12, 25));
    add(afterChristmas, 'christmas-1', '1er dimanche après Noël', 'temps_noel', LiturgicalColorInfo.whiteGold,
        sunday: true);
    final secondAfterChristmas = _add(afterChristmas, 7);
    if (secondAfterChristmas.isBefore(DateTime(y + 1, 1, 6))) {
      add(secondAfterChristmas, 'christmas-2', '2e dimanche après Noël', 'temps_noel', LiturgicalColorInfo.whiteGold,
          sunday: true);
    }
    add(DateTime(y, 12, 31), 'new-year-eve', "Veille du Nouvel An", 'temps_noel', LiturgicalColorInfo.whiteGold,
        note: "Dans la tradition méthodiste, soir de veillée et de renouvellement de l'alliance avec Dieu.");
    add(DateTime(y + 1, 1, 1), 'new-year', "Jour de l'An", 'temps_noel', LiturgicalColorInfo.whiteGold);

    // Epiphany and the weeks after it.
    final epiphany = DateTime(y + 1, 1, 6);
    add(epiphany, 'epiphany', "Épiphanie du Seigneur", 'epiphanie', LiturgicalColorInfo.whiteGold,
        sunday: epiphany.weekday == DateTime.sunday,
        note: "Le Christ se manifeste aux nations, figurées par les mages venus l'adorer.");
    final baptism = sundayAfter(epiphany);
    final transfiguration = _add(e, -49);
    add(baptism, 'epiphany-1', 'Baptême du Seigneur (1er dimanche après l\'Épiphanie)', 'ordinaire_epiphanie',
        LiturgicalColorInfo.white,
        sunday: true, note: "On se souvient du baptême de Jésus dans le Jourdain, et de notre propre baptême.");
    var n = 2;
    for (var d = _add(baptism, 7); d.isBefore(transfiguration); d = _add(d, 7), n++) {
      add(d, 'epiphany-$n', _sunday(n, "après l'Épiphanie"), 'ordinaire_epiphanie', LiturgicalColorInfo.green,
          sunday: true);
    }
    add(transfiguration, 'transfiguration', 'Dimanche de la Transfiguration (dernier dimanche après l\'Épiphanie)',
        'ordinaire_epiphanie', LiturgicalColorInfo.white,
        sunday: true, note: "Jésus apparaît dans sa gloire sur la montagne ; la porte du Carême s'ouvre.");

    // Lent and Holy Week.
    add(ashWednesday, 'ash-wednesday', 'Mercredi des Cendres', 'careme', LiturgicalColorInfo.purple,
        note: "Entrée en Carême : quarante jours (les dimanches exclus) de repentir et de préparation à Pâques.");
    for (var i = 1; i <= 5; i++) {
      add(_add(e, -49 + 7 * i), 'lent-$i', _sunday(i, 'de Carême'), 'careme', LiturgicalColorInfo.purple, sunday: true);
    }
    add(_add(e, -7), 'palm-sunday', 'Dimanche des Rameaux et de la Passion (6e dimanche de Carême)', 'careme',
        LiturgicalColorInfo.holyWeek,
        sunday: true,
        note: "Jésus entre à Jérusalem acclamé, puis la Passion est lue : début de la Semaine sainte.");
    add(_add(e, -6), 'holy-monday', 'Lundi saint', 'careme', LiturgicalColorInfo.holyWeek);
    add(_add(e, -5), 'holy-tuesday', 'Mardi saint', 'careme', LiturgicalColorInfo.holyWeek);
    add(_add(e, -4), 'holy-wednesday', 'Mercredi saint', 'careme', LiturgicalColorInfo.holyWeek);
    add(_add(e, -3), 'holy-thursday', 'Jeudi saint', 'careme', LiturgicalColorInfo.holyWeek,
        note: "Soir du dernier repas de Jésus avec ses disciples, de l'institution de la Cène et du lavement des pieds. "
            "Du soir du Jeudi saint au soir de Pâques, les « Trois Grands Jours » forment un seul ensemble.");
    add(_add(e, -2), 'good-friday', 'Vendredi saint', 'careme', LiturgicalColorInfo.none,
        note: "On fait mémoire de la crucifixion et de la mort du Christ.");
    add(_add(e, -1), 'holy-saturday', 'Samedi saint', 'careme', LiturgicalColorInfo.none,
        note: "Jour de silence et d'attente auprès du tombeau ; la veillée pascale peut commencer le soir.");

    // Easter season.
    add(e, 'easter', 'Dimanche de Pâques (Résurrection du Seigneur)', 'temps_paques', LiturgicalColorInfo.whiteGold,
        sunday: true, note: "Le Christ est ressuscité : c'est la fête centrale de l'année chrétienne.");
    for (var i = 2; i <= 6; i++) {
      add(_add(e, 7 * (i - 1)), 'easter-$i', _sunday(i, 'de Pâques'), 'temps_paques', LiturgicalColorInfo.whiteGold,
          sunday: true);
    }
    add(_add(e, 39), 'ascension', "Ascension du Seigneur", 'temps_paques', LiturgicalColorInfo.white,
        note: "Quarante jours après Pâques, le Christ monte au ciel (le jeudi).");
    add(_add(e, 42), 'easter-7', '7e dimanche de Pâques', 'temps_paques', LiturgicalColorInfo.whiteGold, sunday: true);

    // Pentecost and the season after it.
    add(pentecost, 'pentecost', 'Dimanche de Pentecôte', 'pentecote', LiturgicalColorInfo.red,
        sunday: true, note: "L'Esprit saint est répandu sur les disciples : naissance de l'Église.");
    final lastSunday = _add(nextAdvent, -7);
    add(_add(pentecost, 7), 'trinity', 'Dimanche de la Trinité (1er dimanche après la Pentecôte)',
        'ordinaire_pentecote', LiturgicalColorInfo.white,
        sunday: true, note: "On célèbre Dieu, Père, Fils et Saint-Esprit.");
    var k = 2;
    for (var d = _add(pentecost, 14); d.isBefore(lastSunday); d = _add(d, 7), k++) {
      add(d, 'pentecost+$k', _sunday(k, 'après la Pentecôte'), 'ordinaire_pentecote', LiturgicalColorInfo.green,
          sunday: true);
    }
    add(lastSunday, 'christ-the-king', 'Dimanche du Christ Roi (dernier dimanche après la Pentecôte)',
        'ordinaire_pentecote', LiturgicalColorInfo.white,
        sunday: true, note: "Dernier dimanche de l'année chrétienne : on proclame la royauté du Christ.");
    add(DateTime(y + 1, 11, 1), 'all-saints', 'Toussaint', 'ordinaire_pentecote', LiturgicalColorInfo.white,
        note: "On rend grâce pour tous les saints, connus et inconnus. "
            "Beaucoup d'églises la célèbrent le dimanche le plus proche.");
    add(DateTime(y + 1, 5, 24), 'aldersgate', "Journée d'Aldersgate", 'ordinaire_pentecote',
        LiturgicalColorInfo.green,
        note: "Le 24 mai 1738, à Aldersgate, John Wesley sentit son cœur « étrangement réchauffé » : "
            "date repère du mouvement méthodiste.");

    _addSpecials(y, add, e, pentecost);

    // By date; on the same date the Sunday or feast of the Christian year
    // comes first (it is what [dayOn] returns), its special Sunday last.
    final order = {for (var i = 0; i < days.length; i++) days[i]: i};
    days.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      if (a.isSpecial != b.isSpecial) return a.isSpecial ? 1 : -1;
      if (a.isSunday != b.isSunday) return a.isSunday ? -1 : 1;
      return order[a]! - order[b]!;
    });
    // Fixed dates of the year before Advent 1 or after the next Advent are
    // not part of this church year.
    return [for (final d in days) if (!d.date.isBefore(a1) && d.date.isBefore(nextAdvent)) d];
  }

  /// Special Sundays whose date follows from a rule (Discipline ¶ 263 to
  /// 265). The ones set by each annual conference or congregation are not
  /// computed.
  static void _addSpecials(
    int y,
    void Function(DateTime, String, String, String, LiturgicalColorInfo,
            {bool sunday, bool special, String? note, String? rule})
        add,
    DateTime easter,
    DateTime pentecost,
  ) {
    String season(DateTime d) {
      for (final s in seasons(y)) {
        if (s.contains(d)) return s.id;
      }
      return 'ordinaire_pentecote';
    }

    LiturgicalColorInfo seasonColor(DateTime d) {
      for (final s in seasons(y)) {
        if (s.contains(d)) return s.color;
      }
      return LiturgicalColorInfo.green;
    }

    void special(DateTime d, String id, String name, String rule, String source, String note,
        [LiturgicalColorInfo? color]) {
      add(d, id, name, season(d), color ?? seasonColor(d),
          sunday: d.weekday == DateTime.sunday, special: true, rule: '$rule ($source)', note: note);
    }

    // Human Relations Day: the Sunday before Martin Luther King Jr. Day
    // (the third Monday of January).
    final jan1 = DateTime(y + 1, 1, 1);
    final firstMonday = _add(jan1, (8 - jan1.weekday) % 7);
    final kingDay = _add(firstMonday, 14);
    special(_add(kingDay, -1), 'special-human-relations', 'Journée des relations humaines',
        "Dimanche précédant l'anniversaire de Martin Luther King Jr.", 'Discipline ¶ 263.1',
        "Offrande dans toute l'Église : reconnaître le droit de tous les enfants de Dieu à s'épanouir dans leurs relations.");

    special(_add(easter, -21), 'special-umcor', "Dimanche de l'UMCOR",
        'Quatrième dimanche de Carême', 'Discipline ¶ 263.2',
        "Offrande dans toute l'Église pour partager la bonté de la vie avec ceux qui souffrent.");

    final thirdEaster = _add(easter, 14);
    special(thirdEaster, 'special-native-american', 'Dimanche des ministères amérindiens',
        'Troisième dimanche de Pâques', 'Discipline ¶ 263.6 et Livre de culte',
        "Offrande dans toute l'Église pour les ministères amérindiens.");

    special(_add(pentecost, 7), 'special-peace-justice', 'Dimanche de la paix avec la justice',
        'Premier dimanche après la Pentecôte', 'Discipline ¶ 263.5',
        "Offrande dans toute l'Église : le shalom de Dieu appelle à un monde juste et en paix.");

    final oct1 = DateTime(y + 1, 10, 1);
    final firstOctSunday = sundayOnOrAfter(oct1);
    special(firstOctSunday, 'special-world-communion', 'Dimanche de la communion mondiale',
        "Premier dimanche d'octobre", 'Discipline ¶ 263.3',
        "Offrande dans toute l'Église : l'Église est appelée à être inclusive, un seul corps à la table du Seigneur.");
    special(_add(firstOctSunday, 14), 'special-laity', 'Dimanche des laïcs',
        "De préférence le troisième dimanche d'octobre", 'Discipline ¶ 264.2',
        "On célèbre le ministère de tous les chrétiens laïcs.");

    final nov1 = DateTime(y + 1, 11, 1);
    special(_add(sundayOnOrAfter(nov1), 7), 'special-organ-donor', "Dimanche du don d'organes et de tissus",
        'De préférence le deuxième dimanche de novembre', 'Discipline ¶ 264.3',
        "Journée de sensibilisation, sans offrande.");

    // Heritage Sunday: Aldersgate Day (24 May) or the Sunday before it.
    final aldersgate = DateTime(y + 1, 5, 24);
    special(aldersgate.weekday == DateTime.sunday ? aldersgate : sundayBefore(aldersgate), 'special-heritage',
        'Dimanche du patrimoine', "Jour d'Aldersgate (24 mai) ou le dimanche précédent", 'Discipline ¶ 264.1',
        "Occasion de réfléchir au patrimoine de l'Église et de célébrer son histoire.");
  }
}
