import 'package:flutter_test/flutter_test.dart';
import 'package:emu_compagnon/shared/bible_reference_parser.dart';

void main() {
  group('BibleReferenceParser', () {
    test('detects a simple book+chapter reference', () {
      final matches = BibleReferenceParser.findAll('Voir Genèse 12 pour le contexte.');
      expect(matches, hasLength(1));
      expect(matches.first.book, 'Genèse');
      expect(matches.first.chapter, 12);
      expect(matches.first.verse, isNull);
    });

    test('detects chapter.verse with a dot separator', () {
      final matches = BibleReferenceParser.findAll('Jean 3.16 est bien connu.');
      expect(matches, hasLength(1));
      expect(matches.first.book, 'Jean');
      expect(matches.first.chapter, 3);
      expect(matches.first.verse, 16);
    });

    test('detects chapter:verse with a colon separator', () {
      final matches = BibleReferenceParser.findAll('Jean 3:16 est bien connu.');
      expect(matches.first.verse, 16);
    });

    test('takes the start verse of a range like 2.1-12', () {
      final matches = BibleReferenceParser.findAll('Matthieu 2.1-12 raconte les mages.');
      expect(matches.first.chapter, 2);
      expect(matches.first.verse, 1);
    });

    test('handles numbered books like "1 Corinthiens" as a single unit', () {
      final matches = BibleReferenceParser.findAll('1 Corinthiens 13 parle de l\'amour.');
      expect(matches, hasLength(1));
      expect(matches.first.book, '1 Corinthiens');
      expect(matches.first.chapter, 13);
    });

    test('finds multiple references separated by semicolons', () {
      final matches = BibleReferenceParser.findAll('Genèse 12;Genèse 15;Romains 4');
      expect(matches, hasLength(3));
      expect(matches.map((m) => m.book), ['Genèse', 'Genèse', 'Romains']);
    });

    test('returns no matches for text with no Bible reference', () {
      final matches = BibleReferenceParser.findAll('Ceci est un texte ordinaire.');
      expect(matches, isEmpty);
    });
  });
}
