import 'package:emu_compagnon/features/church_texts/data/church_texts_data.dart';
import 'package:emu_compagnon/features/church_texts/models/church_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final texts = ChurchTextsData.all;

  test('eight texts, each with a unique id and some content', () {
    expect(texts, hasLength(8));
    expect(texts.map((t) => t.id).toSet(), hasLength(8));
    for (final t in texts) {
      expect(t.blocks, isNotEmpty, reason: t.id);
      expect(t.source, isNotEmpty, reason: t.id);
    }
  });

  test('the articles and the confession are complete', () {
    int articles(ChurchText t) =>
        t.headings.where((h) => h.startsWith('Article ')).length;
    expect(articles(ChurchTextsData.articlesOfReligion), 25);
    expect(articles(ChurchTextsData.confessionOfFaith), 16);
  });

  test('seven membership vows', () {
    final vows = ChurchTextsData.membershipVows.blocks
        .where((b) => b.kind == TextBlockKind.item);
    expect(vows, hasLength(7));
  });

  test('the litany answers every call', () {
    final blocks = ChurchTextsData.socialCreedLitany.blocks;
    expect(blocks.where((b) => b.kind == TextBlockKind.people), hasLength(6));
    expect(blocks.last.kind, TextBlockKind.people);
  });

  test('no leftover from the machine translation', () {
    for (final t in texts) {
      for (final b in t.blocks) {
        expect(b.text.contains('­'), isFalse, reason: '${t.id}: soft hyphen');
        expect(b.text.contains('  '), isFalse, reason: '${t.id}: double space');
        expect(b.text.trim(), b.text, reason: t.id);
      }
    }
  });

  test('plain text for sharing carries title, bullets and source', () {
    final shared = ChurchTextsData.membershipVows.toPlainText();
    expect(shared, startsWith('Les vœux des membres'));
    expect('•'.allMatches(shared), hasLength(7));
    expect(shared, contains('¶ 217'));
    expect(shared, endsWith('ÉMU Compagnon'));
  });
}
