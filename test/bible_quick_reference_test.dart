import 'package:flutter_test/flutter_test.dart';
import 'package:emu_compagnon/shared/bible_quick_reference.dart';

void main() {
  (String, int, int?)? parse(String q) {
    final m = BibleQuickReference.parse(q);
    return m == null ? null : (m.book, m.chapter, m.verse);
  }

  group('BibleQuickReference.parse', () {
    test('accepts the usual ways of writing chapter and verse', () {
      expect(parse('Jean 3.16'), ('Jean', 3, 16));
      expect(parse('Jean 3:16'), ('Jean', 3, 16));
      expect(parse('Jean 3 16'), ('Jean', 3, 16));
      expect(parse('Jean 3,16'), ('Jean', 3, 16));
      expect(parse('Jean 3'), ('Jean', 3, null));
      expect(parse('  Psaumes 23  '), ('Psaumes', 23, null));
    });

    test('comprend les noms swahilis des livres', () {
      expect(parse('Yohana 3:16'), ('Jean', 3, 16));
      expect(parse('zaburi 23'), ('Psaumes', 23, null));
      expect(parse('Mwanzo 1'), ('Genèse', 1, null));
      expect(parse('1 Wakorintho 13.4'), ('1 Corinthiens', 13, 4));
      expect(parse('Ufunuo 21'), ('Révélation', 21, null));
      expect(parse('Mathayo 5.3'), ('Matthieu', 5, 3));
    });

    test('ignores case and accents', () {
      expect(parse('jean 3.16'), ('Jean', 3, 16));
      expect(parse('GENESE 1'), ('Genèse', 1, null));
      expect(parse('esaie 53.5'), ('Esaïe', 53, 5));
    });

    test('understands numbered books, with or without a space', () {
      expect(parse('1 Corinthiens 13'), ('1 Corinthiens', 13, null));
      expect(parse('1corinthiens 13.4'), ('1 Corinthiens', 13, 4));
      expect(parse('2 rois 5'), ('2 Rois', 5, null));
    });

    test('understands common abbreviations', () {
      expect(parse('Gn 1.1'), ('Genèse', 1, 1));
      expect(parse('ps 23'), ('Psaumes', 23, null));
      expect(parse('1 co 13'), ('1 Corinthiens', 13, null));
    });

    test('accepts the start of a book name when it is unambiguous', () {
      expect(parse('gen 1'), ('Genèse', 1, null));
      expect(parse('apo 21'), ('Révélation', 21, null)); // "Apocalypse" is accepted too
      expect(parse('Apocalypse 22.21'), ('Révélation', 22, 21));
      expect(parse('cant 2'), ('Cantique', 2, null));
      expect(parse('rev 21'), ('Révélation', 21, null));
      // "Jean" is a full name, so it wins over "Jérémie" even though both start with "j".
      expect(parse('jean 1'), ('Jean', 1, null));
    });

    test('rejects what is not a single clear reference', () {
      expect(parse('amour'), isNull);
      expect(parse('grâce 5'), isNull);
      expect(parse('j 3'), isNull); // too short
      expect(parse('je 3'), isNull); // Jean? Jérémie? ambiguous
      expect(parse('Jean'), isNull); // no chapter
      expect(parse('Jean 0'), isNull);
      expect(parse(''), isNull);
    });
  });
}
