import 'dart:io';

import 'package:emu_compagnon/features/hymns/utils/hymn_stanza_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late String lyrics;
  setUpAll(() async {
    final copy = File('${Directory.systemTemp.path}/hymn377_test.db');
    File('assets/db/app_data.db').copySync(copy.path);
    final db = await databaseFactoryFfi.openDatabase(copy.path,
        options: OpenDatabaseOptions(readOnly: true));
    final rows = await db.rawQuery(
        "SELECT lyrics FROM hymns WHERE number = '377' AND hymnal = 'CV'");
    lyrics = rows.single['lyrics'] as String;
    await db.close();
  });

  test('« Dieu tout puissant » : quatre couplets, chacun avec son propre chœur', () {
    final s = HymnStanzaParser.parse(lyrics);
    expect(s.map((x) => x.label).toList(),
        ['1', 'Chœur', '2', 'Chœur', '3', 'Chœur', '4', 'Chœur']);
    expect(s.where((x) => x.isRefrain).length, 4);
    // trois chœurs différents, pas le même répété
    final choirs = s.where((x) => x.isRefrain).map((x) => x.body).toSet();
    expect(choirs.length, 4);
  });

  test('chaque chœur reprend ses deux vers, comme on les chante', () {
    final choirs =
        HymnStanzaParser.parse(lyrics).where((x) => x.isRefrain).toList();
    expect(choirs[0].body, contains('Dieu tout puissant, que tu es grand'));
    expect('De tout mon être'.allMatches(choirs[0].body).length, 2);
    expect(choirs[1].body, contains('Dieu créateur, que tu es grand'));
    expect(choirs[2].body, contains('Que tu es bon, oh Dieu d\'amour'));
    expect('Alors mon cœur'.allMatches(choirs[2].body).length, 2);
    expect(choirs[3].body, contains('Rien n\'est plus grand que ton amour'));
    expect('Rien n\'est plus grand que ton amour'.allMatches(choirs[3].body).length, 3);
  });

  test('plus de « Chœur x2 » sans texte, et les couplets sont ceux fournis', () {
    expect(lyrics.contains('x2'), isFalse);
    final s = HymnStanzaParser.parse(lyrics);
    expect(s[0].body, startsWith('Dieu tout puissant, quand mon cœur considère'));
    expect(s[2].body, startsWith('Quand par les bois, ou la forêt profonde'));
    expect(s[4].body, startsWith('Mais quand je songe au sublime mystère'));
    expect(s[6].body, startsWith('Quand mon sauveur, éclatant de lumière'));
  });
}
