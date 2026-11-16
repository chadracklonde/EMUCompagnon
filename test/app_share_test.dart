import 'package:emu_compagnon/shared/services/app_share_service.dart';
import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/more/screens/more_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('le lien Play Store porte l\'identifiant de l\'application', () {
    expect(AppShareService.playStoreUrl('com.exemple.app'),
        'https://play.google.com/store/apps/details?id=com.exemple.app');
    expect(AppShareService.fallbackPackageId.contains('.'), isTrue);
  });

  test('le message contient le lien, en français et en swahili', () {
    const url = 'https://play.google.com/store/apps/details?id=x.y';
    final fr = AppShareService.message('fr', url);
    final sw = AppShareService.message('sw', url);
    expect(fr, contains(url));
    expect(sw, contains(url));
    expect(fr, contains('Je vous recommande'));
    expect(sw, contains('Ninakupendekezea'));
    expect(fr, isNot(contains('{url}')));
    // Le lien est suivi d'un second paragraphe : l'auteur et ses coordonnées.
    final parts = fr.split('\n\n');
    expect(parts.length, 2);
    expect(parts.first, endsWith(url));
    expect(parts.last, contains('Chadrack T. Londe'));
    expect(parts.last, contains('+243814479335 (WhatsApp)'));
    expect(parts.last, contains('chadracktambwe+dev@gmail.com'));
    expect(sw.split('\n\n').last, contains('chadracktambwe+dev@gmail.com'));
  });

  testWidgets('l\'écran Plus propose de recommander l\'application, dans la langue choisie', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.load();
    await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: const MaterialApp(home: MoreScreen()),
    ));
    await tester.scrollUntilVisible(find.text("Recommander l'application"), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text("Recommander l'application"), findsOneWidget);
    await settings.setLocale('sw');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Pendekeza programu'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Pendekeza programu'), findsOneWidget);
  });
}
