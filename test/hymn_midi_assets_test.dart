import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:emu_compagnon/features/hymns/data/hymn_midi_assets.dart';

void main() {
  test('chaque entrée de la table pointe vers un fichier existant', () {
    expect(hymnMidiFiles.length, 128);
    for (final f in hymnMidiFiles.values) {
      expect(File('assets/cantiquest/instrumidi/$f').existsSync(), isTrue, reason: f);
    }
  });

  test('hymnMidiAssetFor gère suffixes, zéros initiaux et absence de MIDI', () {
    expect(hymnMidiAssetFor('5'), endsWith('CV_005-polyinstru-Jesus_Jesus.mid'));
    expect(hymnMidiAssetFor('45a'), contains('CV_045a'));
    expect(hymnMidiAssetFor('272'), isNot(contains('soprano')));
    expect(hymnMidiAssetFor('1'), isNull);
  });
}
