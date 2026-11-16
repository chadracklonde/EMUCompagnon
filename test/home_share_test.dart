import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('l\'accueil propose de recommander l\'application : icône en haut et carte en bas', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.load();
    await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    // L'icône est dans l'en-tête, à côté de la langue, du thème et des réglages.
    expect(find.byTooltip("Recommander l'application"), findsOneWidget);
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);

    // La carte est en bas de l'accueil, sous « Faire connaître ».
    await tester.scrollUntilVisible(find.text('Faire connaître'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Faire connaître'), findsOneWidget);
    expect(find.text('Envoyer le lien Play Store à un proche'), findsOneWidget);

    await settings.setLocale('sw');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Tangaza programu'), findsOneWidget);
    // L'en-tête est sorti de l'écran : on remonte pour voir l'icône.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip('Pendekeza programu'), findsOneWidget);

    // Laisse passer les relances du verset du jour (base absente en test).
    await tester.pump(const Duration(seconds: 3));
  });
}
