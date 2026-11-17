import '../../../shared/text_normalizer.dart';
import '../../church_texts/data/church_texts_data.dart';
import '../../church_texts/models/church_text.dart';
import '../../liturgy/data/liturgical_calendar_data.dart';
import '../../liturgy/data/sacraments_data.dart';
import '../../liturgy/data/worship_order_data.dart';

enum ContentHitKind { churchText, worshipOrder, sacrament, liturgicalPeriod }

/// One result found in the liturgy pages or in "Prières et textes".
class ContentHit {
  final ContentHitKind kind;

  /// Title of the matching passage (an article, a step, a season…).
  final String title;

  /// Where it lives, shown above the excerpt ("Articles de religion").
  final String location;
  final String excerpt;

  /// Id of the church text, sacrament or liturgical period.
  final String? id;

  /// For a church text: which heading to open at.
  final int? headingIndex;

  const ContentHit({
    required this.kind,
    required this.title,
    required this.location,
    required this.excerpt,
    this.id,
    this.headingIndex,
  });
}

/// Searches the content written into the app itself (not the database):
/// prayers and doctrinal texts, order of worship, sacraments, calendar.
class ContentSearch {
  static List<_Entry>? _index;

  static List<ContentHit> search(String query, {int limit = 30}) {
    final words = normalizeForSearch(query).split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return const [];
    final inTitle = <ContentHit>[];
    final inBody = <ContentHit>[];
    for (final e in _index ??= _buildIndex()) {
      if (words.every(e.title.contains)) {
        inTitle.add(e.hit);
      } else if (words.every(e.all.contains)) {
        inBody.add(e.hit);
      }
    }
    final hits = [...inTitle, ...inBody];
    return hits.length > limit ? hits.sublist(0, limit) : hits;
  }

  static List<_Entry> _buildIndex() {
    final entries = <_Entry>[];
    void add(ContentHit hit, String body) => entries.add(_Entry(
          hit,
          normalizeForSearch(hit.title),
          normalizeForSearch('${hit.title} ${hit.location} $body'),
        ));

    for (final text in ChurchTextsData.all) {
      final headings = text.headings;
      if (headings.isEmpty) {
        final body = text.blocks.map((b) => b.text).join(' ');
        add(
          ContentHit(
            kind: ContentHitKind.churchText,
            title: text.title,
            location: 'Prières et textes',
            excerpt: body,
            id: text.id,
          ),
          '${text.subtitle} $body',
        );
        continue;
      }
      // One entry per section, so a result opens at the right article.
      var headingIndex = -1;
      String? title;
      var body = <String>[];
      void flush() {
        if (body.isEmpty && title == null) return;
        add(
          ContentHit(
            kind: ContentHitKind.churchText,
            title: title ?? text.title,
            location: title == null ? 'Prières et textes' : text.title,
            excerpt: body.join(' '),
            id: text.id,
            headingIndex: headingIndex < 0 ? null : headingIndex,
          ),
          body.join(' '),
        );
      }

      for (final block in text.blocks) {
        if (block.kind == TextBlockKind.heading) {
          flush();
          headingIndex++;
          title = block.text;
          body = [];
        } else {
          body.add(block.text);
        }
      }
      flush();
    }

    for (final step in WorshipOrderData.steps) {
      add(
        ContentHit(
          kind: ContentHitKind.worshipOrder,
          title: step.title,
          location: 'Ordre du culte',
          excerpt: step.description,
        ),
        step.description,
      );
    }
    for (final s in SacramentsData.items) {
      add(
        ContentHit(
          kind: ContentHitKind.sacrament,
          title: s.name,
          location: 'Sacrements et rites',
          excerpt: s.description,
          id: s.id,
        ),
        '${s.subtitle} ${s.description}',
      );
    }
    for (final p in LiturgicalCalendarData.periods) {
      add(
        ContentHit(
          kind: ContentHitKind.liturgicalPeriod,
          title: p.name,
          location: 'Calendrier liturgique',
          excerpt: p.description,
          id: p.id,
        ),
        '${p.summary} ${p.colorName} ${p.description}',
      );
    }
    return entries;
  }
}

class _Entry {
  final ContentHit hit;
  final String title;
  final String all;
  _Entry(this.hit, this.title, this.all);
}
