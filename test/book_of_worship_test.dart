import 'dart:convert';
import 'dart:io';

import 'package:emu_compagnon/features/church_texts/data/book_of_worship_data.dart';
import 'package:emu_compagnon/features/church_texts/data/church_texts_data.dart';
import 'package:emu_compagnon/features/church_texts/models/church_text.dart';
import 'package:emu_compagnon/features/liturgy/data/sacraments_data.dart';
import 'package:emu_compagnon/features/liturgy/data/worship_order_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final all = BookOfWorshipData.all;

  test('every text keeps the copyright statement of its page and a link to the original', () {
    expect(all, isNotEmpty);
    for (final t in all) {
      expect(t.id, startsWith('bow_'), reason: t.id);
      expect(t.source, contains('The United Methodist Publishing House'), reason: t.id);
      expect(t.source, contains('Mention de droit d\'auteur'), reason: t.id);
      expect(t.sourceUrl, startsWith('https://www.umcdiscipleship.org/book-of-worship/'), reason: t.id);
    }
  });

  test('the statement is the page\'s own, word for word', () {
    final basic = BookOfWorshipData.basicPattern;
    expect(basic.source, contains('“The Basic Pattern of Worship,” Copyright © 1992 UMPH'));
    expect(BookOfWorshipData.briefGreatThanksgiving.source,
        contains('Copyright © 1972 The Methodist Publishing House; Copyright © 1980, 1985, 1987, 1989, 1992 UMPH. Used by permission.'));
    expect(BookOfWorshipData.confessionOfSin.source, contains('Michael J. O’Donnell Copyright © 1992 UMPH'));
  });

  test('texts are in the app and their ids are unique', () {
    final ids = ChurchTextsData.all.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final t in all) {
      expect(ChurchTextsData.byId(t.id), same(t));
    }
  });

  test('responsive texts alternate leader and people', () {
    final litany = BookOfWorshipData.litanyChurchWorld;
    expect(litany.blocks.where((b) => b.kind == TextBlockKind.people), isNotEmpty);
    expect(litany.blocks.where((b) => b.kind == TextBlockKind.leader), isNotEmpty);
  });

  test('no text is empty and none has stray markers or English left in its headings', () {
    for (final t in all) {
      expect(t.blocks, isNotEmpty, reason: t.id);
      for (final b in t.blocks) {
        expect(b.text.trim(), isNotEmpty, reason: t.id);
        expect(b.text, isNot(contains('\x01')), reason: t.id);
      }
    }
  });

  test('the steps and rites point at texts that exist', () {
    final ids = <String>{
      for (final s in WorshipOrderData.steps) ...s.textIds,
      for (final s in SacramentsData.items) ...s.textIds,
    };
    expect(ids, isNotEmpty);
    for (final id in ids) {
      expect(ChurchTextsData.byId(id), isNotNull, reason: id);
    }
  });

  test('the sources in tools/ produce the data file in the app', () {
    final files = Directory('tools/book_of_worship/texts').listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
    expect(files.length, all.length);
    for (final f in files) {
      final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final match = all.where((t) => t.id == 'bow_${d['slug']}');
      expect(match.length, 1, reason: d['slug'] as String);
      expect(match.first.title, d['title']);
      expect(match.first.blocks.length, (d['blocks'] as List).length);
    }
  });
}
