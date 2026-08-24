import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../bible_reference_parser.dart';
import '../../features/bible/screens/chapter_screen.dart';

/// Renders [text] as normal text, except any recognized Bible reference
/// (e.g. "Jean 3.16") is shown underlined/colored and, when tapped,
/// navigates straight to that chapter (and scrolls to/highlights the verse
/// if one was specified).
class LinkedVerseText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const LinkedVerseText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final linkStyle = baseStyle.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      fontWeight: FontWeight.w600,
    );

    final matches = BibleReferenceParser.findAll(text);
    if (matches.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    int cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      spans.add(TextSpan(
        text: m.rawText,
        style: linkStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () => _openReference(context, m),
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }

  void _openReference(BuildContext context, BibleReferenceMatch m) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChapterScreen(
          book: m.book,
          chapter: m.chapter,
          highlightVerse: m.verse,
        ),
      ),
    );
  }
}
