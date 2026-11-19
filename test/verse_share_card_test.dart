import 'package:emu_compagnon/shared/widgets/verse_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget card) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: Center(child: card)),
  ));
  await tester.pump();
}

void main() {
  testWidgets('le visuel de partage porte le verset, sa source et l\'invitation Play Store (français)', (tester) async {
    await _pump(
      tester,
      VerseShareCard(
        reference: 'Matthieu 11.28',
        text: 'Venez à moi, vous tous qui êtes fatigués et chargés, et je vous donnerai du repos.',
        label: 'Verset du jour',
        source: VerseShareCard.sourceForBible('LSG1910'),
      ),
    );

    expect(find.text('VERSET DU JOUR'), findsOneWidget);
    expect(find.textContaining('Venez à moi'), findsOneWidget);
    expect(find.text('Matthieu 11.28'), findsOneWidget);
    expect(find.text('Louis Segond 1910'), findsOneWidget);
    expect(find.text('Téléchargez ÉMU Compagnon, gratuit et sans publicité'), findsOneWidget);
    expect(find.text('DISPONIBLE SUR'), findsOneWidget);
    expect(find.text('Google Play'), findsOneWidget);
    expect(find.text(VerseShareCard.playStoreDisplay), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en swahili, l\'invitation et le badge changent, et la licence suit le texte', (tester) async {
    await _pump(
      tester,
      VerseShareCard(
        reference: 'Zaburi 23:1',
        text: 'Bwana ndiye mchungaji wangu, sitapungukiwa na kitu.',
        label: 'Aya',
        source: VerseShareCard.sourceForBible('SCV'),
        locale: 'sw',
      ),
    );

    expect(find.text('AYA'), findsOneWidget);
    expect(find.text('Pakua ÉMU Compagnon, bure na bila matangazo'), findsOneWidget);
    expect(find.text('PATIKANA KWENYE'), findsOneWidget);
    expect(find.textContaining('CC BY-SA 4.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un long extrait (couplet de cantique) rétrécit au lieu de déborder', (tester) async {
    final long = List.generate(9, (i) => 'Ligne ${i + 1} du couplet qui est assez longue pour prendre de la place').join('\n');
    await _pump(
      tester,
      VerseShareCard(reference: '6 — A Dieu soit la Gloire !', text: long, label: 'Cantique', source: 'Chants de Victoire'),
    );
    expect(find.text('CANTIQUE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // La carte garde sa taille de 540 × 675 (1080 × 1350 une fois capturée à 2×).
    expect(tester.getSize(find.byType(VerseShareCard)), const Size(540, 675));
  });
}
