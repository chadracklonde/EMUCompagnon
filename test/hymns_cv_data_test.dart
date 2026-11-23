import 'dart:io';

import 'package:emu_compagnon/features/hymns/utils/hymn_stanza_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late List<Map<String, Object?>> hymns;

  setUpAll(() async {
    final copy = File('${Directory.systemTemp.path}/cv_data_test.db');
    File('assets/db/app_data.db').copySync(copy.path);
    db = await databaseFactoryFfi.openDatabase(copy.path,
        options: OpenDatabaseOptions(readOnly: true));
    hymns = await db.rawQuery(
        "SELECT number, title, lyrics FROM hymns WHERE hymnal = 'CV'");
  });
  tearDownAll(() => db.close());

  test('aucun chœur vide ni réduit à « x2 » dans Chants de Victoire (sauf le 381, texte à fournir)', () {
    final bad = <String>[];
    for (final h in hymns) {
      for (final s in HymnStanzaParser.parse(h['lyrics'] as String)) {
        if (!s.isRefrain) continue;
        final first = s.body.split('\n').first.trim();
        if (RegExp(r'^[\(\{\[]?\s*(x\s?\d|\d\s?x|bis)\s*[\)\}\]]?$', caseSensitive: false).hasMatch(first)) {
          bad.add('${h['number']} : $first');
        }
      }
    }
    expect(bad, isEmpty);
  });

  test('chaque couplet « Chœur » seul reprend un refrain, sauf le 381', () {
    final noText = <String>[];
    for (final h in hymns) {
      final raw = (h['lyrics'] as String).split('\n\n').map((l) => l.trim()).toList();
      final markers = raw.where((l) => RegExp(r'^(Cœur|Chœur|Choeur|Refrain)\s*(x\s?\d|\(x\s?\d\))?$', caseSensitive: false).hasMatch(l)).length;
      final shown = HymnStanzaParser.parse(h['lyrics'] as String).where((s) => s.isRefrain).length;
      if (markers > shown) noText.add('${h['number']}');
    }
    expect(noText, ['381']);
  });

  test('les quatre cantiques qui étaient collés sont séparés, chacun avec ses couplets', () async {
    for (final pair in const [
      ['147a', '147b', 'Seigneur, ce que je réclame'],
      ['149a', '149b', 'Grâce infinie'],
      ['204a', '204b', 'Revêtons notre armure'],
      ['215a', '215b', 'Quand ma route est obscure'],
    ]) {
      final a = hymns.singleWhere((h) => h['number'] == pair[0]);
      final b = hymns.singleWhere((h) => h['number'] == pair[1]);
      expect(b['title'], pair[2]);
      final aNums = HymnStanzaParser.parse(a['lyrics'] as String).where((s) => !s.isRefrain).map((s) => s.label).toList();
      final bNums = HymnStanzaParser.parse(b['lyrics'] as String).where((s) => !s.isRefrain).map((s) => s.label).toList();
      // la numérotation ne redémarre plus au milieu d'un cantique
      for (final nums in [aNums, bNums]) {
        expect(nums, [for (var i = 1; i <= nums.length; i++) '$i'], reason: pair.join(' '));
      }
      expect((a['lyrics'] as String).contains(pair[1]), isFalse);
    }
    expect(hymns.length, 448);
  });

  test('corrections de fautes confirmées par un recueil en ligne', () {
    String ly(String n) => hymns.singleWhere((h) => h['number'] == n)['lyrics'] as String;
    expect(ly('7'), contains('Ou la santé.'));
    expect(ly('21'), contains('Rabboni'));
    expect(ly('60'), contains('Vous tous qui souffrez isolés'));
    expect(ly('129'), isNot(contains('\n\nle grand amour')));
    expect(ly('51').contains('\n\nplus de Sauveur'), isFalse);
    expect(ly('174'), contains('Qu\'en moi ton amour rayonne'));
  });
}
