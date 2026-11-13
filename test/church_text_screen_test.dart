import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/church_texts/data/book_of_worship_data.dart';
import 'package:emu_compagnon/features/church_texts/data/church_texts_data.dart';
import 'package:emu_compagnon/features/church_texts/screens/church_text_screen.dart';
import 'package:emu_compagnon/features/church_texts/screens/church_texts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home) => ChangeNotifierProvider(
      // A fresh key each time, so a second pump starts from [home] again.
      key: UniqueKey(),
      create: (_) => AppSettings(),
      child: MaterialApp(home: home),
    );

void main() {
  testWidgets('every text opens from the list', (tester) async {
    for (final text in ChurchTextsData.all) {
      await tester.pumpWidget(_app(const ChurchTextsScreen()));
      // The list is lazy: scroll down to the row.
      await tester.scrollUntilVisible(find.text(text.title), 300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(text.title));
      await tester.pumpAndSettle();
      expect(find.byType(ChurchTextScreen), findsOneWidget, reason: text.id);
      expect(tester.takeException(), isNull, reason: text.id);
    }
  });

  testWidgets('the table of contents jumps to the chosen article', (tester) async {
    const title = "Article VI — De l'Ancien Testament";
    await tester.pumpWidget(
      _app(const ChurchTextScreen(text: ChurchTextsData.articlesOfReligion)),
    );
    // Too far down to be on screen when the page opens.
    expect(tester.getTopLeft(find.text(title)).dy, greaterThan(600));

    await tester.tap(find.byTooltip('Sommaire'));
    await tester.pumpAndSettle();
    // Listed in the sheet, on top of the page.
    expect(find.text(title), findsNWidgets(2));
    await tester.tap(find.text(title).last);
    await tester.pumpAndSettle();

    expect(find.text(title), findsOneWidget);
    expect(tester.getTopLeft(find.text(title)).dy, inInclusiveRange(0, 599));
  });

  testWidgets('short texts have no table of contents', (tester) async {
    await tester.pumpWidget(_app(const ChurchTextScreen(text: ChurchTextsData.lordsPrayer)));
    expect(find.byTooltip('Sommaire'), findsNothing);
  });

  testWidgets('a text with a Swahili version is shown in Swahili when the app is in Swahili', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.setLocale('sw');
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(home: ChurchTextScreen(text: BookOfWorshipData.blessingsClosing)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Baraka na sala ya kufunga'), findsWidgets);
    expect(find.text('Bénédictions et prière de clôture'), findsNothing);
    expect(tester.takeException(), isNull);

    // Without a Swahili version, the French text stays.
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(home: ChurchTextScreen(key: UniqueKey(), text: BookOfWorshipData.basicPattern)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Le schéma de base du culte'), findsWidgets);
  });

  testWidgets('the list can be searched, and clearing the search brings the groups back', (tester) async {
    await tester.pumpWidget(_app(const ChurchTextsScreen()));
    expect(find.text('Ce que nous croyons'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'mariage');
    await tester.pumpAndSettle();
    expect(find.text('Culte de mariage chrétien II'), findsOneWidget);
    expect(find.text('Le Notre Père'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('Aucun texte ne correspond.'), findsOneWidget);

    await tester.tap(find.byTooltip('Effacer'));
    await tester.pumpAndSettle();
    expect(find.text('Le Notre Père'), findsWidgets);
  });
}
