import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/church_texts/data/church_texts_data.dart';
import 'package:emu_compagnon/features/church_texts/screens/church_text_screen.dart';
import 'package:emu_compagnon/features/church_texts/screens/church_texts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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
      await tester.ensureVisible(find.text(text.title));
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
}
