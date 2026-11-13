import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/shared/widgets/hymn_audio_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('la note de musique porte une étiquette dans la langue choisie', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.load();
    await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: const MaterialApp(home: Scaffold(body: HymnAudioMark())),
    ));
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('Enregistrement disponible'), findsOneWidget);
    await settings.setLocale('sw');
    await tester.pump();
    expect(find.bySemanticsLabel('Sauti inapatikana'), findsOneWidget);
  });
}
