import 'package:flutter_test/flutter_test.dart';
import 'package:emu_compagnon/features/hymns/utils/hymn_stanza_parser.dart';

void main() {
  group('HymnStanzaParser', () {
    test('splits numbered verses and a Cœur refrain into distinct stanzas', () {
      const lyrics =
          "(mi bémol)\n\n1. À Dieu soit la Gloire !\n\nPar son Grand Amour\n\n"
          "Cœur\n\nGloire à Dieu !\n\nTerre, écoute sa voix !\n\n"
          "2. De Jésus, la joie,\n\nRemplit notre cœur ;";

      final stanzas = HymnStanzaParser.parse(lyrics);

      expect(stanzas.length, 3);
      expect(stanzas[0].label, '1');
      expect(stanzas[0].isRefrain, false);
      expect(stanzas[0].body, contains('À Dieu soit la Gloire'));

      expect(stanzas[1].label, 'Cœur');
      expect(stanzas[1].isRefrain, true);
      expect(stanzas[1].body, contains('Gloire à Dieu'));

      expect(stanzas[2].label, '2');
      expect(stanzas[2].isRefrain, false);
      expect(stanzas[2].body, contains('De Jésus, la joie'));
    });

    test('drops a leading lone musical-key line without losing lyrics', () {
      const lyrics = "(fa)\n\n1. Premier couplet ici.";
      final stanzas = HymnStanzaParser.parse(lyrics);
      expect(stanzas.length, 1);
      expect(stanzas.first.body, isNot(contains('(fa)')));
      expect(stanzas.first.body, contains('Premier couplet ici'));
    });

    test('falls back to a single unlabeled block when no markers are found', () {
      const lyrics = "Une ligne.\n\nUne autre ligne.";
      final stanzas = HymnStanzaParser.parse(lyrics);
      expect(stanzas, isNotEmpty);
      expect(stanzas.map((s) => s.body).join(' '), contains('Une ligne'));
      expect(stanzas.map((s) => s.body).join(' '), contains('Une autre ligne'));
    });

    test('recognizes Refrain and Chœur as refrain markers too', () {
      const lyrics = "1. Couplet.\n\nRefrain\n\nParoles du refrain.";
      final stanzas = HymnStanzaParser.parse(lyrics);
      expect(stanzas.last.isRefrain, true);
      expect(stanzas.last.label, 'Refrain');
    });
  });
}
