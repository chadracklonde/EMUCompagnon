import 'package:flutter_test/flutter_test.dart';
import 'package:emu_compagnon/features/hymn_lists/models/hymn_list.dart';

void main() {
  const sunday = HymnList(id: 'a', name: 'Culte du dimanche', numbers: ['18', '4', '152']);
  const youth = HymnList(id: 'b', name: 'Jeunesse', numbers: []);

  group('HymnListCodec encode / decode', () {
    test('round-trips lists with their order', () {
      final decoded = HymnListCodec.decode(HymnListCodec.encode([sunday, youth]));
      expect(decoded.map((l) => l.id), ['a', 'b']);
      expect(decoded.first.name, 'Culte du dimanche');
      expect(decoded.first.numbers, ['18', '4', '152']);
      expect(decoded.last.numbers, isEmpty);
    });

    test('unreadable data gives no lists instead of failing', () {
      expect(HymnListCodec.decode(null), isEmpty);
      expect(HymnListCodec.decode(''), isEmpty);
      expect(HymnListCodec.decode('not json'), isEmpty);
      expect(HymnListCodec.decode('{"id":"a"}'), isEmpty);
    });

    test('a malformed entry is skipped without losing the others', () {
      final decoded = HymnListCodec.decode(
        '[{"id":"a","name":"Bon","numbers":["1",2,"3"]},{"name":"sans id"},42]',
      );
      expect(decoded.single.name, 'Bon');
      expect(decoded.single.numbers, ['1', '3']);
    });
  });

  group('HymnListCodec.merge', () {
    test('adds lists that only the backup has, after the local ones', () {
      expect(HymnListCodec.merge([sunday], [youth]).map((l) => l.id), ['a', 'b']);
    });

    test('never overwrites a local list with the backup version', () {
      const older = HymnList(id: 'a', name: 'Ancien nom', numbers: ['1']);
      final merged = HymnListCodec.merge([sunday], [older]);
      expect(merged.single.name, 'Culte du dimanche');
      expect(merged.single.numbers, ['18', '4', '152']);
    });

    test('importing the same backup twice changes nothing', () {
      final once = HymnListCodec.merge([sunday], [youth]);
      expect(HymnListCodec.merge(once, [youth]).length, 2);
    });
  });

  group('editing the hymns of a list', () {
    test('a hymn is added at the end, and only once', () {
      expect(HymnListCodec.withHymn(['18', '4'], '7'), ['18', '4', '7']);
      expect(HymnListCodec.withHymn(['18', '4'], '4'), ['18', '4']);
    });

    test('a moved hymn ends up at the position asked for', () {
      expect(HymnListCodec.moved(['a', 'b', 'c'], 0, 2), ['b', 'c', 'a']);
      expect(HymnListCodec.moved(['a', 'b', 'c'], 0, 1), ['b', 'a', 'c']);
      expect(HymnListCodec.moved(['a', 'b', 'c'], 2, 0), ['c', 'a', 'b']);
      expect(HymnListCodec.moved(['a', 'b', 'c'], 1, 1), ['a', 'b', 'c']);
      expect(HymnListCodec.moved(['a', 'b', 'c'], 0, 99), ['b', 'c', 'a']);
      expect(HymnListCodec.moved(['a', 'b', 'c'], 9, 0), ['a', 'b', 'c']);
    });
  });
}
