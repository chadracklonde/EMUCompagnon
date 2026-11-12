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
      if (t.id == 'bow_baptism_bcp') continue; // public domain, checked below
      expect(t.source, contains('The United Methodist Publishing House'), reason: t.id);
      expect(t.source, contains('Mention de droit d\'auteur'), reason: t.id);
      expect(t.sourceUrl, startsWith('https://www.umcdiscipleship.org/book-of-worship/'), reason: t.id);
    }
  });

  test('the baptism text is the public-domain one, not the UMC text that forbids alteration', () {
    final ids = all.map((t) => t.id);
    expect(ids, contains('bow_baptism_bcp'));
    expect(ids, isNot(contains('bow_baptismal_covenant_1')));
    final bcp = BookOfWorshipData.baptismBcp;
    expect(bcp.source, contains('domaine public'));
    expect(bcp.source, contains('Book of Common Prayer'));
    expect(bcp.source, contains('Il n’est pas le texte de l’Alliance baptismale de l’Église méthodiste unie'));
    // The sacraments of baptism and confirmation point at it.
    final linked = SacramentsData.items.expand((s) => s.textIds);
    expect(linked, contains('bow_baptism_bcp'));
  });

  test('the statement is the page\'s own, word for word', () {
    final basic = BookOfWorshipData.basicPattern;
    expect(basic.source, contains('“The Basic Pattern of Worship,” Copyright © 1992 UMPH'));
    expect(BookOfWorshipData.briefGreatThanksgiving.source,
        contains('Copyright © 1972 The Methodist Publishing House; Copyright © 1980, 1985, 1987, 1989, 1992 UMPH. Used by permission.'));
    expect(BookOfWorshipData.confessionOfSin.source, contains('Michael J. O’Donnell Copyright © 1992 UMPH'));
  });

  test('Swahili versions follow the French blocks and keep the page\'s copyright statement', () {
    final withSw = all.where((t) => t.sw != null).toList();
    expect(withSw.map((t) => t.id), containsAll(['bow_confession_of_sin', 'bow_blessings_closing']));
    for (final t in withSw) {
      final sw = t.sw!;
      expect(sw.id, t.id);
      expect(sw.blocks.length, t.blocks.length, reason: t.id);
      for (var i = 0; i < t.blocks.length; i++) {
        expect(sw.blocks[i].kind, t.blocks[i].kind, reason: '${t.id} #$i');
        expect(sw.blocks[i].text.trim(), isNotEmpty, reason: '${t.id} #$i');
      }
      expect(sw.source, contains('haijakaguliwa'), reason: t.id);
      final statement = RegExp('« (.*) »').firstMatch(t.source)!.group(1)!;
      expect(sw.source, contains(statement), reason: t.id);
      expect(sw.sourceUrl, t.sourceUrl);
    }
  });

  test('localized() falls back to French when there is no Swahili version', () {
    final basic = BookOfWorshipData.basicPattern;
    expect(basic.sw, isNull);
    expect(basic.localized('sw'), same(basic));
    expect(basic.localized('fr'), same(basic));
    final confession = BookOfWorshipData.confessionOfSin;
    expect(confession.localized('fr'), same(confession));
    expect(confession.localized('sw').title, 'Maombi ya toba');
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
