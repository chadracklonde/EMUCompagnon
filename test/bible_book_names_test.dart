import 'package:emu_compagnon/features/bible/repository/bible_repository.dart';
import 'package:emu_compagnon/shared/bible_book_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('66 noms swahilis, un par livre', () {
    expect(BibleBookNames.sw.length, BibleRepository.books.length);
    expect(BibleBookNames.sw.toSet().length, 66);
  });

  test('noms swahilis quand la langue est le swahili ou la Bible SCV', () {
    expect(BibleBookNames.display('Genèse', locale: 'fr', version: 'LSG1910'), 'Genèse');
    expect(BibleBookNames.display('Genèse', locale: 'sw', version: 'LSG1910'), 'Mwanzo');
    expect(BibleBookNames.display('Genèse', locale: 'fr', version: 'SCV'), 'Mwanzo');
    expect(BibleBookNames.display('Révélation', locale: 'fr', version: 'SCV'), 'Ufunuo');
    expect(BibleBookNames.display('Psaumes', locale: 'fr', version: 'SCV'), 'Zaburi');
    expect(BibleBookNames.display('Jean', locale: 'fr', version: 'SCV'), 'Yohana');
  });

  test('les références sont réécrites', () {
    expect(BibleBookNames.displayReference('1 Corinthiens 13.4', locale: 'sw'), '1 Wakorintho 13.4');
    expect(BibleBookNames.displayReference('Jean 3.16', locale: 'fr', version: 'LSG1910'), 'Jean 3.16');
  });
}
