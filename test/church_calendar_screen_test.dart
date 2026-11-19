import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/liturgy/screens/church_day_screen.dart';
import 'package:emu_compagnon/features/liturgy/screens/liturgical_calendar_screen.dart';
import 'package:emu_compagnon/features/liturgy/services/church_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _app(Widget home) => ChangeNotifierProvider(
      key: UniqueKey(),
      create: (_) => AppSettings(),
      child: MaterialApp(home: home),
    );

void main() {
  testWidgets('the calendar shows the current year and moves to the next and previous ones', (tester) async {
    await tester.pumpWidget(_app(const LiturgicalCalendarScreen()));
    final start = ChurchCalendar.churchYearStartFor(DateTime.now());
    expect(find.text('Année chrétienne $start–${start + 1}'), findsOneWidget);
    expect(find.text('Année lectionnaire ${ChurchCalendar.lectionaryYear(start)}'), findsOneWidget);

    await tester.tap(find.byTooltip('Année suivante'));
    await tester.pumpAndSettle();
    expect(find.text('Année chrétienne ${start + 1}–${start + 2}'), findsOneWidget);
    expect(find.text("Revenir à aujourd'hui"), findsOneWidget);

    await tester.tap(find.byTooltip('Année précédente'));
    await tester.tap(find.byTooltip('Année précédente'));
    await tester.pumpAndSettle();
    expect(find.text('Année chrétienne ${start - 1}–$start'), findsOneWidget);

    await tester.tap(find.text("Revenir à aujourd'hui"));
    await tester.pumpAndSettle();
    expect(find.text('Année chrétienne $start–${start + 1}'), findsOneWidget);
  });

  testWidgets('the list shows Sundays and feasts, and the special Sundays can be switched off', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(const LiturgicalCalendarScreen()));
    final listView = find.byType(Scrollable).first;
    // The list is lazy: scroll to the entry.
    await tester.scrollUntilVisible(find.text('Dimanche de la communion mondiale'), 400, scrollable: listView);
    expect(find.text('Dimanche de la communion mondiale'), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(SwitchListTile), -400, scrollable: listView);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    // The October Sundays sit just above All Saints in the list.
    await tester.scrollUntilVisible(find.text('Toussaint'), 400, scrollable: listView);
    await tester.drag(listView, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('Dimanche de la communion mondiale'), findsNothing);
    expect(find.text('Dimanche des laïcs'), findsNothing);
  });

  testWidgets('a day opens its detail', (tester) async {
    final easter = ChurchCalendar.churchYear(2026).firstWhere((d) => d.id == 'easter');
    await tester.pumpWidget(_app(ChurchDayScreen(day: easter)));
    expect(find.text('Dimanche de Pâques (Résurrection du Seigneur)'), findsOneWidget);
    expect(find.text('dimanche 28 mars 2027'), findsOneWidget);
    expect(find.text('Blanc ou or'), findsOneWidget);
  });

  testWidgets('a special Sunday explains how its date is fixed', (tester) async {
    final day = ChurchCalendar.churchYear(2026).firstWhere((d) => d.id == 'special-world-communion');
    await tester.pumpWidget(_app(ChurchDayScreen(day: day)));
    expect(find.textContaining('Premier dimanche d\'octobre'), findsOneWidget);
    expect(find.textContaining('Discipline ¶ 263.3'), findsOneWidget);
  });

  testWidgets('Ash Wednesday and Good Friday link to their services', (tester) async {
    for (final entry in {'ash-wednesday': 'Culte du mercredi des Cendres', 'good-friday': 'Culte du Vendredi saint', 'palm-sunday': 'Culte du dimanche de la Passion / des Rameaux', 'holy-thursday': 'Culte du jeudi saint (soir)'}.entries) {
      final day = ChurchCalendar.churchYear(2026).firstWhere((d) => d.id == entry.key);
      await tester.pumpWidget(_app(ChurchDayScreen(day: day)));
      expect(find.text('Pour célébrer ce jour'), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  test('long dates in French', () {
    expect(frenchLongDate(DateTime(2027, 3, 28)), 'dimanche 28 mars 2027');
    expect(frenchLongDate(DateTime(2026, 12, 25)), 'vendredi 25 décembre 2026');
  });
}
