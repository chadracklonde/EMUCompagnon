import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../shared/bible_reference_parser.dart';
import '../screens/chapter_screen.dart';

/// Un morceau de texte d'une note, avec sa mise en forme.
class NoteRun {
  final String text;
  final bool italic;
  final bool bold;
  final bool heading;
  final bool ref;
  const NoteRun(this.text,
      {this.italic = false,
      this.bold = false,
      this.heading = false,
      this.ref = false});
}

/// Un paragraphe (ou une puce) d'une note.
class NoteBlock {
  final List<NoteRun> runs;
  final bool bullet;
  const NoteBlock(this.runs, {this.bullet = false});
  String get plain => runs.map((r) => r.text).join();

  /// Vrai pour un titre seul (« 1 à 2 : Le chaos »).
  bool get isHeading => runs.isNotEmpty && runs.every((r) => r.heading || r.text.trim().isEmpty);
}

final _token =
    RegExp(r'<(/?)(p|i|b|h|ref|ul|li|br)\s*/?>', caseSensitive: false);

String _decodeEntities(String s) => s
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&');

/// Lit une note dans le petit langage de balises : p, i, b, h, ref, ul, li, br.
List<NoteBlock> parseNote(String html) {
  final blocks = <NoteBlock>[];
  var runs = <NoteRun>[];
  var bullet = false;
  var italic = 0, bold = 0, heading = 0, ref = 0;

  void flush() {
    final text = runs.map((r) => r.text).join().trim();
    if (text.isNotEmpty) blocks.add(NoteBlock(runs, bullet: bullet));
    runs = <NoteRun>[];
    bullet = false;
  }

  void addText(String raw) {
    final text = _decodeEntities(raw).replaceAll(RegExp(r'[ \t\r\n]+'), ' ');
    if (text.isEmpty) return;
    runs.add(NoteRun(text,
        italic: italic > 0,
        bold: bold > 0,
        heading: heading > 0,
        ref: ref > 0));
  }

  var cursor = 0;
  for (final m in _token.allMatches(html)) {
    addText(html.substring(cursor, m.start));
    cursor = m.end;
    final closing = m.group(1) == '/';
    switch (m.group(2)!.toLowerCase()) {
      case 'p':
        flush();
      case 'li':
        flush();
        if (!closing) bullet = true;
      case 'ul':
        flush();
      case 'br':
        runs.add(const NoteRun('\n'));
      case 'i':
        italic += closing ? -1 : 1;
      case 'b':
        bold += closing ? -1 : 1;
      case 'h':
        heading += closing ? -1 : 1;
      case 'ref':
        ref += closing ? -1 : 1;
    }
  }
  addText(html.substring(cursor));
  flush();
  // Les espaces de début et de fin de paragraphe n'ont pas de sens.
  return [
    for (final b in blocks)
      NoteBlock([
        for (var i = 0; i < b.runs.length; i++)
          NoteRun(
            i == 0
                ? b.runs[i].text.trimLeft()
                : (i == b.runs.length - 1
                    ? b.runs[i].text.trimRight()
                    : b.runs[i].text),
            italic: b.runs[i].italic,
            bold: b.runs[i].bold,
            heading: b.runs[i].heading,
            ref: b.runs[i].ref,
          )
      ], bullet: b.bullet)
  ];
}

/// Affiche une note : paragraphes, italique, mots commentés en gras, titres
/// et références bibliques cliquables quand elles sont reconnues.
///
/// Avec [firstBlockOnly], seuls s'affichent les titres du début et le premier
/// paragraphe, ce dernier limité à [maxLines] lignes (aperçu du mode Étude).
class NoteText extends StatelessWidget {
  final String html;
  final TextStyle? style;
  final bool firstBlockOnly;
  final int? maxLines;

  const NoteText(this.html,
      {super.key, this.style, this.firstBlockOnly = false, this.maxLines});

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final scheme = Theme.of(context).colorScheme;
    var blocks = parseNote(html);
    if (firstBlockOnly) {
      final head = <NoteBlock>[];
      for (final b in blocks) {
        head.add(b);
        if (!b.isHeading) break;
      }
      blocks = head;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final b in blocks)
          Padding(
            padding: EdgeInsets.only(bottom: firstBlockOnly && !b.isHeading ? 0 : 10),
            child: Text.rich(
              TextSpan(
                style: base,
                children: [
                  if (b.bullet) const TextSpan(text: '•  '),
                  for (final r in b.runs) _span(context, r, base, scheme),
                ],
              ),
              maxLines: b.isHeading ? null : maxLines,
              overflow: maxLines == null || b.isHeading ? null : TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  InlineSpan _span(
      BuildContext context, NoteRun r, TextStyle base, ColorScheme scheme) {
    var s = base;
    if (r.italic) s = s.copyWith(fontStyle: FontStyle.italic);
    if (r.bold) s = s.copyWith(fontWeight: FontWeight.w700);
    if (r.heading)
      s = s.copyWith(fontWeight: FontWeight.w700, color: scheme.primary);
    if (!r.ref) return TextSpan(text: r.text, style: s);

    final match = BibleReferenceParser.findAll(r.text).firstOrNull;
    final refStyle =
        s.copyWith(color: scheme.primary, fontWeight: FontWeight.w600);
    if (match == null) return TextSpan(text: r.text, style: refStyle);
    return TextSpan(
      text: r.text,
      style: refStyle.copyWith(decoration: TextDecoration.underline),
      recognizer: TapGestureRecognizer()
        ..onTap = () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChapterScreen(
                  book: match.book,
                  chapter: match.chapter,
                  highlightVerse: match.verse),
            )),
    );
  }
}
