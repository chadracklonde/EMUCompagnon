import 'package:emu_compagnon/features/liturgy/services/church_calendar.dart';
import 'package:emu_compagnon/features/liturgy/services/liturgical_calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int y, int m, int day) => DateTime(y, m, day);

void main() {
  // "Calendar for dating Easter and related holy days", UM Book of Worship
  // (Discipleship Ministries): Ash Wednesday, Easter, Pentecost, Advent 1.
  const table = {
    2013: [(2, 13), (3, 31), (5, 19), (12, 1)],
    2014: [(3, 5), (4, 20), (6, 8), (11, 30)],
    2015: [(2, 18), (4, 5), (5, 24), (11, 29)],
    2016: [(2, 10), (3, 27), (5, 15), (11, 27)],
    2017: [(3, 1), (4, 16), (6, 4), (12, 3)],
    2018: [(2, 14), (4, 1), (5, 20), (12, 2)],
    2019: [(3, 6), (4, 21), (6, 9), (12, 1)],
    2020: [(2, 26), (4, 12), (5, 31), (11, 29)],
  };

  group('dates against the Book of Worship table', () {
    table.forEach((year, row) {
      test('$year', () {
        // The church year of this table row: Ash Wednesday, Easter and
        // Pentecost of [year]; Advent 1 of [year].
        final days = ChurchCalendar.churchYear(year - 1);
        DateTime on(String id) => days.firstWhere((x) => x.id == id).date;
        expect(on('ash-wednesday'), d(year, row[0].$1, row[0].$2));
        expect(on('easter'), d(year, row[1].$1, row[1].$2));
        expect(on('pentecost'), d(year, row[2].$1, row[2].$2));
        expect(ChurchCalendar.advent1(year), d(year, row[3].$1, row[3].$2));
      });
    });
  });

  group('Easter and Advent beyond the table', () {
    test('Easter 2021–2030', () {
      const easters = {
        2021: (4, 4), 2022: (4, 17), 2023: (4, 9), 2024: (3, 31), 2025: (4, 20),
        2026: (4, 5), 2027: (3, 28), 2028: (4, 16), 2029: (4, 1), 2030: (4, 21),
      };
      easters.forEach((year, md) => expect(ChurchCalendar.easter(year), d(year, md.$1, md.$2), reason: '$year'));
    });

    test('Advent 1, 2021–2027', () {
      const advents = {
        2021: (11, 28), 2022: (11, 27), 2023: (12, 3), 2024: (12, 1), 2025: (11, 30),
        2026: (11, 29), 2027: (11, 28),
      };
      advents.forEach((year, md) => expect(ChurchCalendar.advent1(year), d(year, md.$1, md.$2), reason: '$year'));
    });

    test('Advent 1 when Christmas falls on a Sunday (2033: 27 November, not 4 December)', () {
      expect(ChurchCalendar.advent1(2033), d(2033, 11, 27));
      expect(ChurchCalendar.advent1(2022), d(2022, 11, 27));
      expect(LiturgicalCalendarService.periodsForChurchYear(2033).first.start, d(2033, 11, 27));
    });

    test('Advent 1 is always a Sunday between 27 November and 3 December', () {
      for (var y = 1900; y <= 2200; y++) {
        final a = ChurchCalendar.advent1(y);
        expect(a.weekday, DateTime.sunday, reason: '$y');
        final ok = (a.month == 11 && a.day >= 27) || (a.month == 12 && a.day <= 3);
        expect(ok, isTrue, reason: '$y: $a');
      }
    });
  });

  group('the lectionary year', () {
    test('A, B, C in turn (page of the Book of Worship: Advent 2026 starts year B)', () {
      expect(ChurchCalendar.lectionaryYear(2025), 'A');
      expect(ChurchCalendar.lectionaryYear(2026), 'B');
      expect(ChurchCalendar.lectionaryYear(2027), 'C');
      expect(ChurchCalendar.lectionaryYear(2028), 'A');
      expect(ChurchCalendar.lectionaryYear(2022), 'A');
    });
  });

  group('a whole church year', () {
    for (final start in [2024, 2025, 2026, 2027, 2028, 2030, 2040, 2100]) {
      test('$start: every Sunday is named, none twice, in order', () {
        final days = ChurchCalendar.churchYear(start, specials: false);
        final first = ChurchCalendar.advent1(start);
        final next = ChurchCalendar.advent1(start + 1);

        for (var s = first; s.isBefore(next); s = d(s.year, s.month, s.day + 7)) {
          final sundays = days.where((x) => x.date == s && x.isSunday).toList();
          expect(sundays.length, 1, reason: '$s has ${sundays.map((x) => x.id)}');
        }
        for (var i = 1; i < days.length; i++) {
          expect(days[i].date.isBefore(days[i - 1].date), isFalse);
        }
        expect(days.every((x) => !x.date.isBefore(first) && x.date.isBefore(next)), isTrue);
        expect({for (final x in days) '${x.id}'}.length, days.length);
      });
    }
  });

  group('the days', () {
    test('2026–2027 (Easter 28 March 2027)', () {
      final days = ChurchCalendar.churchYear(2026, specials: false);
      DateTime on(String id) => days.firstWhere((x) => x.id == id).date;
      expect(on('advent-1'), d(2026, 11, 29));
      expect(on('advent-4'), d(2026, 12, 20));
      expect(on('christmas'), d(2026, 12, 25));
      expect(on('christmas-1'), d(2026, 12, 27));
      expect(on('epiphany'), d(2027, 1, 6));
      expect(on('epiphany-1'), d(2027, 1, 10));
      expect(on('transfiguration'), d(2027, 2, 7));
      expect(on('ash-wednesday'), d(2027, 2, 10));
      expect(on('lent-1'), d(2027, 2, 14));
      expect(on('palm-sunday'), d(2027, 3, 21));
      expect(on('holy-thursday'), d(2027, 3, 25));
      expect(on('good-friday'), d(2027, 3, 26));
      expect(on('easter'), d(2027, 3, 28));
      expect(on('ascension'), d(2027, 5, 6));
      expect(on('pentecost'), d(2027, 5, 16));
      expect(on('trinity'), d(2027, 5, 23));
      expect(on('christ-the-king'), d(2027, 11, 21));
      expect(on('all-saints'), d(2027, 11, 1));
    });

    test('the page of the Book of Worship: 15 Nov 2026 is the 25th Sunday after Pentecost, 22 Nov the last', () {
      final day = ChurchCalendar.dayOn(d(2026, 11, 15))!;
      expect(day.id, 'pentecost+25');
      expect(day.name, '25e dimanche après la Pentecôte');
      expect(ChurchCalendar.dayOn(d(2026, 11, 22))!.id, 'christ-the-king'); // the 26th and last
      // 29 Nov 2026 starts the next church year.
      expect(ChurchCalendar.dayOn(d(2026, 11, 29))!.id, 'advent-1');
      expect(ChurchCalendar.churchYearStartFor(d(2026, 11, 28)), 2025);
      expect(ChurchCalendar.churchYearStartFor(d(2026, 11, 29)), 2026);
    });

    test('Sundays after Epiphany and after Pentecost vary with Easter', () {
      int count(int start, String prefix) =>
          ChurchCalendar.churchYear(start, specials: false).where((x) => x.id.startsWith(prefix)).length;
      // Early Easter (2024: 31 March) leaves few Sundays after Epiphany; late Easter (2025: 20 April) more.
      expect(count(2023, 'epiphany-'), lessThan(count(2024, 'epiphany-')));
    });

    test('a Sunday that is also a feast is named by the Sunday', () {
      // Christmas Day 2022 fell on a Sunday.
      expect(ChurchCalendar.dayOn(d(2022, 12, 25))!.id, 'christmas');
      // 1 November 2026 is a Sunday: the Sunday after Pentecost leads, All Saints is also listed.
      final ids = ChurchCalendar.daysOn(d(2026, 11, 1)).map((x) => x.id);
      expect(ids, containsAll(['all-saints']));
    });

    test('second Sunday after Christmas only when it exists', () {
      expect(ChurchCalendar.churchYear(2025).any((x) => x.id == 'christmas-2'), isTrue); // Christmas 2025 is a Thursday: 4 Jan
      expect(ChurchCalendar.churchYear(2023).any((x) => x.id == 'christmas-2'), isFalse); // Christmas 2023 is a Monday: next Sunday is 7 Jan
    });
  });

  group('colours', () {
    test('seasons and days', () {
      expect(ChurchCalendar.colorOn(d(2026, 12, 6)).name, contains('Violet'));
      expect(ChurchCalendar.colorOn(d(2027, 5, 16)).name, 'Rouge');
      expect(ChurchCalendar.colorOn(d(2027, 3, 26)).name, contains('Aucune'));
      expect(ChurchCalendar.colorOn(d(2027, 7, 14)).name, 'Vert');
      expect(ChurchCalendar.colorOn(d(2027, 5, 23)).name, 'Blanc'); // Trinity
      expect(ChurchCalendar.colorOn(d(2027, 3, 28)).name, contains('Blanc'));
    });
  });

  group('special Sundays (Discipline ¶ 263 to 265)', () {
    test('2026–2027', () {
      final days = ChurchCalendar.churchYear(2026).where((x) => x.isSpecial);
      DateTime on(String id) => days.firstWhere((x) => x.id == id).date;
      expect(on('special-human-relations'), d(2027, 1, 17)); // MLK Day is Monday 18 January 2027
      expect(on('special-umcor'), d(2027, 3, 7)); // 4th Sunday of Lent
      expect(on('special-native-american'), d(2027, 4, 11)); // 3rd Sunday of Easter
      expect(on('special-peace-justice'), d(2027, 5, 23));
      expect(on('special-heritage'), d(2027, 5, 23)); // 24 May 2027 is a Monday: the Sunday before
      expect(on('special-world-communion'), d(2027, 10, 3));
      expect(on('special-laity'), d(2027, 10, 17));
      expect(on('special-organ-donor'), d(2027, 11, 14));
    });

    test('every one falls on a Sunday and carries its rule', () {
      for (var y = 2020; y <= 2060; y++) {
        for (final s in ChurchCalendar.churchYear(y).where((x) => x.isSpecial)) {
          expect(s.date.weekday, DateTime.sunday, reason: '$y ${s.id}');
          expect(s.rule, isNotNull);
        }
      }
    });

    test('they can be left out', () {
      expect(ChurchCalendar.churchYear(2026, specials: false).any((x) => x.isSpecial), isFalse);
    });
  });

  group('consistency with the seasons already shown', () {
    test('same start dates as LiturgicalCalendarService', () {
      for (final year in [2024, 2025, 2026, 2027, 2033]) {
        final old = LiturgicalCalendarService.periodsForChurchYear(year);
        final spans = ChurchCalendar.seasons(year);
        DateTime oldStart(String id) => old.firstWhere((p) => p.period.id == id).start;
        expect(spans.firstWhere((s) => s.id == 'avent').start, oldStart('avent'), reason: '$year');
        expect(spans.firstWhere((s) => s.id == 'careme').start, oldStart('careme'), reason: '$year');
        expect(spans.firstWhere((s) => s.id == 'temps_paques').start, oldStart('paques'), reason: '$year');
        expect(spans.firstWhere((s) => s.id == 'pentecote').start, oldStart('pentecote'), reason: '$year');
      }
    });
  });

  group('looking up a date', () {
    test('the season of any date', () {
      expect(ChurchCalendar.seasonOn(d(2027, 2, 20)).id, 'careme');
      expect(ChurchCalendar.seasonOn(d(2027, 1, 20)).id, 'ordinaire_epiphanie');
      expect(ChurchCalendar.seasonOn(d(2026, 12, 30)).id, 'temps_noel');
    });

    test('the next Sunday', () {
      expect(ChurchCalendar.nextSunday(d(2026, 11, 12))!.date, d(2026, 11, 15));
      expect(ChurchCalendar.nextSunday(d(2026, 11, 15))!.date, d(2026, 11, 15));
    });
  });
}
