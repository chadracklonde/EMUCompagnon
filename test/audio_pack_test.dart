import 'dart:convert';
import 'dart:io';

import 'package:emu_compagnon/core/settings/app_settings.dart';
import 'package:emu_compagnon/features/audio_pack/hymn_audio_pack.dart';
import 'package:emu_compagnon/features/audio_pack/hymn_audio_store.dart';
import 'package:emu_compagnon/features/audio_pack/hymn_audio_store_io.dart';
import 'package:emu_compagnon/features/audio_pack/screens/audio_pack_offer_screen.dart';
import 'package:emu_compagnon/features/audio_pack/widgets/audio_pack_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Stockage en mémoire, pour tester le pack sans fichiers.
class MemoryStore implements HymnAudioStore {
  final Map<String, List<int>> files = {};
  @override
  bool supported = true;
  @override
  Future<String?> pathIfValid(String name, int size) async =>
      files[name]?.length == size ? '/mem/$name' : null;
  @override
  Future<void> write(String name, List<int> bytes) async => files[name] = bytes;
  @override
  Future<void> clear() async => files.clear();
}

const _files = [AudioFile('1.m4a', 10), AudioFile('2.m4a', 20), AudioFile('3.m4a', 30)];

/// Un faux serveur : répond avec le bon nombre d'octets, sauf pour les noms de [bad]
/// (mauvaise taille) et les adresses qui contiennent [missingOn] (erreur 404).
http.Client _server({Set<String> bad = const {}, String? missingOn, List<String>? log}) {
  return MockClient((request) async {
    log?.add(request.url.toString());
    final url = request.url.toString();
    if (missingOn != null && url.contains(missingOn)) return http.Response('no', 404);
    final name = url.split('/').last;
    final size = _files.firstWhere((f) => f.name == name).size;
    return http.Response.bytes(List.filled(bad.contains(name) ? size - 1 : size, 7), 200);
  });
}

HymnAudioPack _pack(MemoryStore store, http.Client client) =>
    HymnAudioPack(store: store, client: client, files: _files);

void main() {
  sqfliteFfiInit();

  group('liste des enregistrements fournie avec l\'application', () {
    test('correspond exactement aux fichiers de hymn_audio/ et à la base', () async {
      final manifest = jsonDecode(File('assets/hymn_audio_manifest.json').readAsStringSync()) as Map;
      final listed = {for (final f in manifest['files'] as List) f['name'] as String: f['size'] as int};
      final onDisk = {
        for (final f in Directory('hymn_audio').listSync().whereType<File>())
          f.uri.pathSegments.last: f.lengthSync()
      };
      expect(listed, onDisk);
      expect(listed.length, 121);

      final copy = File('${Directory.systemTemp.path}/audio_manifest_test.db');
      File('assets/db/app_data.db').copySync(copy.path);
      final db = await databaseFactoryFfi
          .openDatabase(copy.path, options: OpenDatabaseOptions(readOnly: true));
      final rows = await db.rawQuery('SELECT audio_url FROM hymns WHERE audio_url IS NOT NULL');
      await db.close();
      final inDb = {for (final r in rows) (r['audio_url'] as String).split('/').last};
      expect(inDb, listed.keys.toSet());
    });
  });

  group('téléchargement', () {
    test('télécharge tout, un fichier à la fois, en essayant main d\'abord', () async {
      final store = MemoryStore();
      final log = <String>[];
      final pack = _pack(store, _server(log: log));
      await pack.load();
      expect((pack.installed, pack.total, pack.totalBytes), (0, 3, 60));
      var notified = 0;
      pack.addListener(() => notified++);
      await pack.start();
      expect(pack.complete, isTrue);
      expect(pack.installedBytes, 60);
      expect(pack.state, AudioPackState.idle);
      expect(notified, greaterThanOrEqualTo(4));
      expect(log.first, contains('/EMUCompagnon/main/hymn_audio/1.m4a'));
      expect(await pack.localPath('hymn_audio/2.m4a'), '/mem/2.m4a');
      expect(await pack.localPath('hymn_audio/99.m4a'), isNull);
    });

    test('ne retélécharge pas ce qui est déjà là', () async {
      final store = MemoryStore()..files['1.m4a'] = List.filled(10, 1);
      final log = <String>[];
      final pack = _pack(store, _server(log: log));
      await pack.load();
      expect(pack.installed, 1);
      await pack.start();
      expect(log.where((u) => u.endsWith('/1.m4a')), isEmpty);
      expect(pack.complete, isTrue);
    });

    test('un fichier de mauvaise taille n\'est pas gardé : erreur, puis reprise', () async {
      final store = MemoryStore();
      final pack = _pack(store, _server(bad: {'2.m4a'}));
      await pack.load();
      await pack.start();
      expect(pack.state, AudioPackState.error);
      expect(pack.installed, 1); // le premier est gardé
      expect(store.files.containsKey('2.m4a'), isFalse);

      final fixed = HymnAudioPack(store: store, client: _server(), files: _files);
      await fixed.load();
      expect(fixed.installed, 1);
      await fixed.start();
      expect(fixed.complete, isTrue);
    });

    test('si main répond 404, la branche de travail prend le relais', () async {
      final store = MemoryStore();
      final log = <String>[];
      final pack = _pack(store, _server(missingOn: '/EMUCompagnon/main/', log: log));
      await pack.load();
      await pack.start();
      expect(pack.complete, isTrue);
      expect(log.any((u) => u.contains('/claude/magical-turing-k431w4/')), isTrue);
    });

    test('sans réseau : erreur claire, rien de gardé à moitié', () async {
      final store = MemoryStore();
      final pack = _pack(store, MockClient((_) async => throw const SocketException('hors ligne')));
      await pack.load();
      await pack.start();
      expect(pack.state, AudioPackState.error);
      expect(pack.installed, 0);
      expect(store.files, isEmpty);
    });

    test('arrêter garde les fichiers reçus ; supprimer les efface', () async {
      final store = MemoryStore();
      late HymnAudioPack pack;
      var calls = 0;
      pack = _pack(store, MockClient((request) async {
        calls++;
        if (calls == 2) pack.cancel();
        final name = request.url.toString().split('/').last;
        return http.Response.bytes(List.filled(_files.firstWhere((f) => f.name == name).size, 7), 200);
      }));
      await pack.load();
      await pack.start();
      expect(pack.state, AudioPackState.idle);
      expect(pack.installed, lessThan(3));
      expect(pack.installed, greaterThanOrEqualTo(1));
      await pack.remove();
      expect(pack.installed, 0);
      expect(store.files, isEmpty);
    });

    test('sur un appareil sans stockage (web), rien n\'est téléchargeable', () async {
      final store = MemoryStore()..supported = false;
      final pack = _pack(store, _server());
      await pack.start();
      expect(pack.supported, isFalse);
      expect(pack.installed, 0);
      expect(await pack.localPath('hymn_audio/1.m4a'), isNull);
    });
  });

  group('fichiers sur l\'appareil', () {
    test('écriture atomique, taille vérifiée, suppression', () async {
      final dir = Directory.systemTemp.createTempSync('audio_store');
      addTearDown(() => dir.existsSync() ? dir.deleteSync(recursive: true) : null);
      final store = IoHymnAudioStore(() async => Directory('${dir.path}/hymn_audio'));
      expect(await store.pathIfValid('1.m4a', 3), isNull);
      await store.write('1.m4a', [1, 2, 3]);
      expect(await store.pathIfValid('1.m4a', 3), isNotNull);
      expect(await store.pathIfValid('1.m4a', 4), isNull); // mauvaise taille
      expect(Directory('${dir.path}/hymn_audio').listSync().map((e) => e.path.split('/').last), ['1.m4a']);
      await store.clear();
      expect(await store.pathIfValid('1.m4a', 3), isNull);
    });
  });

  group('bloc « Écouter sans connexion »', () {
    Future<Widget> app(HymnAudioPack pack, {String locale = 'fr'}) async {
      SharedPreferences.setMockInitialValues({'settings.locale': locale});
      final settings = AppSettings();
      await settings.load();
      return ChangeNotifierProvider<AppSettings>.value(
        value: settings,
        child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: AudioPackCard(pack: pack)))),
      );
    }

    testWidgets('propose le téléchargement avec sa taille, puis le suppr', (tester) async {
      final pack = _pack(MemoryStore(), _server());
      await tester.pumpWidget(await app(pack));
      await tester.pumpAndSettle();
      expect(find.text('Écouter sans connexion'), findsOneWidget);
      expect(find.text('Pas encore téléchargés'), findsOneWidget);
      expect(find.textContaining('Télécharger ('), findsOneWidget);
      expect(find.textContaining('Wi-Fi'), findsOneWidget);

      await tester.tap(find.textContaining('Télécharger ('));
      await tester.pumpAndSettle();
      expect(pack.complete, isTrue);
      expect(find.textContaining('3 enregistrements téléchargés'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);

      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      expect(pack.installed, 0);
      expect(find.text('Pas encore téléchargés'), findsOneWidget);
    });

    testWidgets('en cas d\'échec : message et « Réessayer » ; en swahili les textes suivent', (tester) async {
      final pack = _pack(MemoryStore(), MockClient((_) async => http.Response('', 500)));
      await tester.pumpWidget(await app(pack, locale: 'sw'));
      await tester.pumpAndSettle();
      expect(find.text('Sikiliza bila mtandao'), findsOneWidget);
      await tester.tap(find.textContaining('Pakua ('));
      await tester.pumpAndSettle();
      expect(pack.state, AudioPackState.error);
      expect(find.text('Jaribu tena'), findsOneWidget);
      expect(find.textContaining('Upakuaji umekatika'), findsOneWidget);
    });

    testWidgets('sur le web : message « non disponible », pas de bouton', (tester) async {
      final pack = _pack(MemoryStore()..supported = false, _server());
      await tester.pumpWidget(await app(pack));
      await tester.pumpAndSettle();
      expect(find.textContaining('pas disponible'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('proposition au démarrage', () {
    test('une seule fois, en français, sur un appareil qui garde des fichiers', () async {
      SharedPreferences.setMockInitialValues({});
      final pack = _pack(MemoryStore(), _server());
      expect(await AudioPackOffer.shouldShow('fr', pack: pack), isTrue);
      expect(await AudioPackOffer.shouldShow('sw', pack: pack), isFalse);
      expect(await AudioPackOffer.shouldShow('fr', pack: _pack(MemoryStore()..supported = false, _server())), isFalse);
      await AudioPackOffer.markShown();
      expect(await AudioPackOffer.shouldShow('fr', pack: pack), isFalse);
    });

    testWidgets('« Plus tard » passe à l\'application ; « Télécharger » puis « Continuer »', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.load();
      final pack = _pack(MemoryStore(), _server());
      Widget host() => ChangeNotifierProvider<AppSettings>.value(
            value: settings,
            child: MaterialApp(
              home: AudioPackOfferScreen(pack: pack, next: (_) => const Scaffold(body: Text('APPLICATION'))),
            ),
          );

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      expect(find.text('Écouter les cantiques sans internet'), findsOneWidget);
      expect(find.text('Plus tard'), findsOneWidget);
      await tester.ensureVisible(find.text('Plus tard'));
      await tester.tap(find.text('Plus tard'));
      await tester.pumpAndSettle();
      expect(find.text('APPLICATION'), findsOneWidget);
      expect(await AudioPackOffer.shouldShow('fr', pack: pack), isFalse); // marquée comme vue

      final pack2 = _pack(MemoryStore(), _server());
      await tester.pumpWidget(ChangeNotifierProvider<AppSettings>.value(
        key: UniqueKey(), // repart d'un navigateur neuf
        value: settings,
        child: MaterialApp(
          home: AudioPackOfferScreen(pack: pack2, next: (_) => const Scaffold(body: Text('APPLICATION'))),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('Télécharger ('));
      await tester.tap(find.textContaining('Télécharger ('));
      await tester.pumpAndSettle();
      expect(pack2.complete, isTrue);
      expect(find.text('Continuer'), findsOneWidget);
    });
  });
}
