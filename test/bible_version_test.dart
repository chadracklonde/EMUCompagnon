import 'package:emu_compagnon/core/models/bible_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la Bible swahilie SCV est disponible avec sa mention de licence', () {
    final v = BibleVersions.byCode('SCV');
    expect(v.available, isTrue);
    expect(v.language, 'Kiswahili');
    expect(v.note, contains('CC BY-SA 4.0'));
    expect(BibleVersions.availableVersions, contains(v));
  });

  test('un code inconnu retombe sur Louis Segond', () {
    expect(BibleVersions.byCode('???').code, 'LSG1910');
  });
}
