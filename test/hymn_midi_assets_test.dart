import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:emu_compagnon/features/hymns/data/hymn_midi_assets.dart';

void main() {
  test('chaque entrée de la table pointe vers un fichier MIDI existant', () {
    for (final n in hymnMidiFiles.keys) {
      final path = hymnMidiAssetFor(n)!;
      final f = File(path);
      expect(f.existsSync(), isTrue, reason: path);
      expect(f.readAsBytesSync().sublist(0, 4), [0x4d, 0x54, 0x68, 0x64], reason: path);
    }
  });

  test('hymnMidiAssetFor gère zéros initiaux et absence de MIDI', () {
    expect(hymnMidiAssetFor('234'), 'assets/midi/ccel/converse.mid');
    expect(hymnMidiAssetFor('0234'), 'assets/midi/ccel/converse.mid');
    expect(hymnMidiAssetFor('1'), isNull);
  });
}
