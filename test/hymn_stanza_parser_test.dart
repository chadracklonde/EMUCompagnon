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

    test('splits verses whose number is written with an escaped dot', () {
      final stanzas = HymnStanzaParser.parse(
        '1. Premier couplet\n\n2\\. Deuxième couplet\n\n3\\. Troisième couplet',
      );
      expect(stanzas.map((s) => s.label), ['1', '2', '3']);
      expect(stanzas[1].body, 'Deuxième couplet');
    });

    test('recognizes Refrain and Chœur as refrain markers too', () {
      const lyrics = "1. Couplet.\n\nRefrain\n\nParoles du refrain.";
      final stanzas = HymnStanzaParser.parse(lyrics);
      expect(stanzas.last.isRefrain, true);
      expect(stanzas.last.label, 'Refrain');
    });

    test('reconnaît Solo comme marqueur de refrain', () {
      const lyrics = "1. Couplet.\n\nSolo\n\nParoles du solo.\n\n2. Autre couplet.";
      final stanzas = HymnStanzaParser.parse(lyrics);
      expect(stanzas.map((s) => s.label), ['1', 'Solo', '2']);
      expect(stanzas[1].isRefrain, true);
    });

    test('un « Chœur » seul reprend le dernier refrain écrit', () {
      const lyrics = '1. Un.\n\nChœur\n\nLe refrain.\n\n2. Deux.\n\nChœur\n\n3. Trois.\n\nChœur';
      final s = HymnStanzaParser.parse(lyrics);
      expect(s.map((x) => x.label), ['1', 'Chœur', '2', 'Chœur', '3', 'Chœur']);
      expect(s.where((x) => x.isRefrain).map((x) => x.body), ['Le refrain.', 'Le refrain.', 'Le refrain.']);
    });

    test('« Chœur x2 » ne montre plus « x2 » : le texte du refrain commence au premier vers', () {
      const lyrics = '1. Un.\n\nChœur x2\n\nPremier vers.\n\n2. Deux.\n\nChœur (x3)\n\nSecond vers.\n\n3. Trois.\n\nChœur X2';
      final s = HymnStanzaParser.parse(lyrics);
      final choirs = s.where((x) => x.isRefrain).map((x) => x.body).toList();
      expect(choirs, ['Premier vers.', 'Second vers.', 'Second vers.']);
    });

    test('des refrains différents à chaque couplet restent différents', () {
      const lyrics = '1. Un.\n\nChœur\n\nPremier.\n\n2. Deux.\n\nChœur\n\nSecond.';
      final s = HymnStanzaParser.parse(lyrics);
      expect(s.where((x) => x.isRefrain).map((x) => x.body), ['Premier.', 'Second.']);
    });

    test('un « Chœur » seul sans refrain écrit auparavant reste invisible, sans erreur', () {
      final s = HymnStanzaParser.parse('1. Un.\n\nChœur\n\n2. Deux.');
      expect(s.map((x) => x.label), ['1', '2']);
    });
  });
}
