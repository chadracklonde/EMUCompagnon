import 'package:emu_compagnon/features/backup/services/backup_service.dart';
import 'package:emu_compagnon/features/church_texts/data/church_texts_data.dart';
import 'package:emu_compagnon/features/church_texts/models/church_text.dart';
import 'package:emu_compagnon/features/church_texts/services/church_text_prefs.dart';
import 'package:emu_compagnon/features/search/repository/content_search.dart';
import 'package:emu_compagnon/features/worship/services/worship_service.dart';
import 'package:emu_compagnon/shared/bible_reference_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('one section of a text', () {
    const text = ChurchTextsData.articlesOfReligion;
    final second = text.blocks.indexWhere((b) => b.text.startsWith('Article II '));

    test('a paragraph belongs to the article above it', () {
      expect(text.sectionTitleOf(second + 1), text.blocks[second].text);
      expect(text.sectionOf(second + 1).first.kind, TextBlockKind.heading);
    });

    test('sharing a section leaves the other articles out', () {
      final shared = text.sectionPlainText(second + 1);
      expect(shared, contains('Article II '));
      expect(shared, isNot(contains('Article I ')));
      expect(shared, isNot(contains('Article III ')));
      expect(shared, contains('— ${text.title}'));
      expect(shared, endsWith('ÉMU Compagnon'));
    });
  });

  group('search in the liturgy and the texts', () {
    test('finds an article by a word of its body, without accents', () {
      final hits = ContentSearch.search('purgatoire');
      expect(hits, isNotEmpty);
      expect(hits.first.kind, ContentHitKind.churchText);
      expect(hits.first.headingIndex, isNotNull);
      expect(ContentSearch.search('PURGATOIRE').length, hits.length);
    });

    test('a title match comes before a body match', () {
      final hits = ContentSearch.search('baptême');
      expect(hits, isNotEmpty);
      expect(hits.first.title.toLowerCase(), contains('baptême'));
    });

    test('covers sacraments, order of worship and calendar', () {
      final kinds = {
        for (final q in ['sainte cene', 'offrande', 'avent'])
          ...ContentSearch.search(q).map((h) => h.kind),
      };
      expect(kinds, contains(ContentHitKind.sacrament));
      expect(kinds, contains(ContentHitKind.liturgicalPeriod));
    });

    test('an empty or unknown query finds nothing', () {
      expect(ContentSearch.search('   '), isEmpty);
      expect(ContentSearch.search('zzxxyyqq'), isEmpty);
    });

    test('every church text result points to an existing text and heading', () {
      for (final hit in ContentSearch.search('Dieu', limit: 500)) {
        if (hit.kind != ContentHitKind.churchText) continue;
        final text = ChurchTextsData.byId(hit.id!);
        expect(text, isNotNull);
        if (hit.headingIndex != null) {
          expect(hit.headingIndex, lessThan(text!.headings.length));
        }
      }
    });
  });

  test('the mission quotes are tappable references', () {
    final refs = [
      for (final b in ChurchTextsData.mission.blocks) ...BibleReferenceParser.findAll(b.text),
    ];
    expect(refs.map((r) => '${r.book} ${r.chapter}.${r.verse}'),
        containsAll(['Matthieu 28.19', 'Matthieu 22.37']));
  });

  test('the service day is today on a Sunday, else the coming Sunday', () {
    // 8 November 2026 is a Sunday.
    expect(WorshipService.serviceDay(DateTime(2026, 11, 8, 9)), DateTime(2026, 11, 8));
    expect(WorshipService.serviceDay(DateTime(2026, 11, 9)), DateTime(2026, 11, 15));
    expect(WorshipService.serviceDay(DateTime(2026, 11, 14, 23)), DateTime(2026, 11, 15));
    expect(WorshipService.serviceDay(DateTime(2026, 12, 28)), DateTime(2027, 1, 3));
  });

  test('pinned texts merge without duplicates', () {
    expect(ChurchTextPrefs.merge(['a', 'b'], ['b', 'c']), ['a', 'b', 'c']);
  });

  group('backup reminder', () {
    final now = DateTime(2026, 11, 11);
    test('never without personal data', () {
      expect(BackupService.reminderDue(itemCount: 0, now: now), isFalse);
    });
    test('due when data was never exported', () {
      expect(BackupService.reminderDue(itemCount: 3, now: now), isTrue);
    });
    test('not after a recent export or a recent "later"', () {
      expect(
        BackupService.reminderDue(itemCount: 3, now: now, lastExport: DateTime(2026, 11, 1)),
        isFalse,
      );
      expect(
        BackupService.reminderDue(itemCount: 3, now: now, snoozedAt: DateTime(2026, 10, 20)),
        isFalse,
      );
    });
    test('due again a month after the last export', () {
      expect(
        BackupService.reminderDue(itemCount: 3, now: now, lastExport: DateTime(2026, 9, 1)),
        isTrue,
      );
    });
  });
}
