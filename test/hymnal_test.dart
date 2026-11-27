import 'dart:io';

import 'package:emu_compagnon/core/database/db_helper.dart';
import 'package:emu_compagnon/core/models/hymnal.dart';
import 'package:emu_compagnon/features/hymn_lists/models/hymn_list.dart';
import 'package:emu_compagnon/features/hymns/utils/hymn_stanza_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  group('recueils', () {
    test('le recueil suit la langue', () {
      expect(Hymnals.forLocale('fr'), 'CV');
      expect(Hymnals.forLocale('sw'), 'NZW');
      expect(Hymnals.name('CV'), 'Chants de Victoire');
      expect(Hymnals.name('NZW'), 'Nyimbo za Wokovu');
    });

    test('une liste ancienne (sans recueil) est une liste des Chants de Victoire', () {
      final old = HymnListCodec.decode('[{"id":"a","name":"Culte","numbers":["1"]}]');
      expect(old.single.hymnal, 'CV');
      const sw = HymnList(id: 'b', name: 'Ibada', numbers: ['5'], hymnal: 'NZW');
      expect(HymnListCodec.decode(HymnListCodec.encode([sw])).single.hymnal, 'NZW');
    });

    test('Kiitikio est reconnu comme refrain', () {
      final stanzas = HymnStanzaParser.parse('1. Beti la kwanza.\n\nKiitikio\n\nManeno ya kiitikio.\n\n2. Beti la pili.');
      expect(stanzas.map((s) => s.label), ['1', 'Kiitikio', '2']);
      expect(stanzas[1].isRefrain, isTrue);
    });
  });

  group('base livrée (assets/db/app_data.db)', () {
    late Database db;
    setUpAll(() async {
      final copy = File('${Directory.systemTemp.path}/hymnal_test.db');
      File('assets/db/app_data.db').copySync(copy.path);
      db = await factory.openDatabase(copy.path, options: OpenDatabaseOptions(readOnly: true));
    });
    tearDownAll(() => db.close());

    test('448 Chants de Victoire et 360 Nyimbo za Wokovu, numérotés de 1 à 360', () async {
      final counts = {
        for (final r in await db.rawQuery('SELECT hymnal, COUNT(*) c FROM hymns GROUP BY hymnal'))
          r['hymnal']: r['c']
      };
      expect(counts, {'CV': 448, 'NZW': 360});
      final numbers = (await db.rawQuery("SELECT number FROM hymns WHERE hymnal = 'NZW'"))
          .map((r) => int.parse(r['number'] as String))
          .toSet();
      expect(numbers, {for (var i = 1; i <= 360; i++) i});
    });

    test('chaque cantique des Nyimbo za Wokovu se découpe en strophes numérotées', () async {
      final rows = await db.rawQuery("SELECT number, lyrics FROM hymns WHERE hymnal = 'NZW'");
      for (final r in rows) {
        final stanzas = HymnStanzaParser.parse(r['lyrics'] as String);
        expect(stanzas.first.label, '1', reason: 'cantique ${r['number']}');
        expect(stanzas.every((s) => s.body.isNotEmpty), isTrue, reason: 'cantique ${r['number']}');
      }
    });

    test('la recherche trouve « damu » dans les Nyimbo za Wokovu seulement', () async {
      final nzw = await db.rawQuery(
          "SELECT COUNT(*) c FROM hymns WHERE hymnal = 'NZW' AND lyrics LIKE '%damu%'");
      final cv = await db.rawQuery(
          "SELECT COUNT(*) c FROM hymns WHERE hymnal = 'CV' AND lyrics LIKE '%damu%'");
      expect(nzw.first['c'] as int, greaterThan(20));
      expect(cv.first['c'], 0);
    });
  });

  group('copie du contenu (mise à jour de la base)', () {
    test('une base sans colonne hymnal est copiée : ses cantiques sont des Chants de Victoire', () async {
      final dir = Directory.systemTemp.createTempSync('copy_test');
      final oldDb = await factory.openDatabase('${dir.path}/old.db');
      await oldDb.execute(
          'CREATE TABLE hymns (id INTEGER PRIMARY KEY, number TEXT NOT NULL, title TEXT NOT NULL, key TEXT, lyrics TEXT NOT NULL, audio_url TEXT)');
      await oldDb.insert('hymns', {'id': 1, 'number': '1', 'title': 'Ancien', 'lyrics': '1. a'});
      await oldDb.close();

      final live = await factory.openDatabase('${dir.path}/live.db');
      await live.execute(
          'CREATE TABLE hymns (id INTEGER PRIMARY KEY, number TEXT NOT NULL, title TEXT NOT NULL, key TEXT, lyrics TEXT NOT NULL, audio_url TEXT, hymnal TEXT)');
      await live.insert('hymns', {'id': 9, 'number': '9', 'title': 'À remplacer', 'lyrics': '1. x', 'hymnal': 'NZW'});
      await live.execute("ATTACH DATABASE '${dir.path}/old.db' AS newdb");
      await live.transaction((txn) => DbHelper.copyTable(txn, 'hymns', 'newdb'));
      final rows = await live.query('hymns');
      expect(rows.length, 1);
      expect(rows.single['title'], 'Ancien');
      expect(rows.single['hymnal'], 'CV');
      await live.close();
      dir.deleteSync(recursive: true);
    });
  });
}
