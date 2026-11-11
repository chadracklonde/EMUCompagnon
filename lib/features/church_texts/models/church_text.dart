/// How one block of a [ChurchText] is laid out on the reading page.
enum TextBlockKind {
  /// Section heading (an article title, a part of the General Rules…).
  heading,

  /// Ordinary paragraph.
  paragraph,

  /// One entry of a list.
  item,

  /// Line said by the leader in a responsive reading.
  leader,

  /// Line said by the whole congregation in a responsive reading.
  people,

  /// Editorial note, set apart from the text itself.
  note,
}

class TextBlock {
  final TextBlockKind kind;
  final String text;

  const TextBlock(this.kind, this.text);
  const TextBlock.heading(this.text) : kind = TextBlockKind.heading;
  const TextBlock.p(this.text) : kind = TextBlockKind.paragraph;
  const TextBlock.item(this.text) : kind = TextBlockKind.item;
  const TextBlock.leader(this.text) : kind = TextBlockKind.leader;
  const TextBlock.people(this.text) : kind = TextBlockKind.people;
  const TextBlock.note(this.text) : kind = TextBlockKind.note;
}

/// Icon of a text, mapped to a Material icon by the screens so the data
/// files stay free of Flutter imports.
enum ChurchTextIcon { prayer, creed, litany, articles, confession, rules, vows, mission }

/// A prayer, creed or doctrinal text of the Church, read as one page.
class ChurchText {
  final String id;
  final String title;
  final String subtitle;
  final ChurchTextIcon icon;

  /// Where the text comes from, shown under it.
  final String source;

  final List<TextBlock> blocks;

  const ChurchText({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.source,
    required this.blocks,
  });

  /// Section headings, in order — the table of contents of long texts.
  List<String> get headings => [
        for (final b in blocks)
          if (b.kind == TextBlockKind.heading) b.text,
      ];

  /// The blocks of the section [blockIndex] belongs to: from the heading
  /// above it to the next heading. A text without headings is one section.
  List<TextBlock> sectionOf(int blockIndex) {
    var start = blockIndex;
    while (start > 0 && blocks[start].kind != TextBlockKind.heading) {
      start--;
    }
    var end = blockIndex + 1;
    while (end < blocks.length && blocks[end].kind != TextBlockKind.heading) {
      end++;
    }
    return blocks.sublist(start, end);
  }

  /// Title of the section [blockIndex] belongs to, or null before the
  /// first heading.
  String? sectionTitleOf(int blockIndex) {
    final first = sectionOf(blockIndex).first;
    return first.kind == TextBlockKind.heading ? first.text : null;
  }

  /// One section as plain lines, for sharing a single article.
  String sectionPlainText(int blockIndex) {
    final buffer = StringBuffer();
    for (final b in sectionOf(blockIndex)) {
      buffer.writeln(_plainLine(b));
      if (b.kind == TextBlockKind.heading) buffer.writeln();
    }
    buffer
      ..writeln()
      ..writeln('— $title')
      ..writeln()
      ..write('ÉMU Compagnon');
    return buffer.toString();
  }

  static String _plainLine(TextBlock b) => switch (b.kind) {
        TextBlockKind.item => '• ${b.text}',
        TextBlockKind.note => '(${b.text})',
        _ => b.text,
      };

  /// Everything a search looks into, as one string.
  String get searchableText =>
      [title, subtitle, for (final b in blocks) b.text].join('\n');

  /// The text as plain lines, for sharing.
  String toPlainText() {
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln();
    for (final b in blocks) {
      switch (b.kind) {
        case TextBlockKind.heading:
          buffer
            ..writeln()
            ..writeln(b.text);
        case TextBlockKind.item:
          buffer.writeln('• ${b.text}');
        case TextBlockKind.note:
          buffer.writeln('(${b.text})');
        case TextBlockKind.paragraph:
        case TextBlockKind.leader:
        case TextBlockKind.people:
          buffer.writeln(b.text);
      }
    }
    buffer
      ..writeln()
      ..writeln('— $source')
      ..writeln()
      ..write('ÉMU Compagnon');
    return buffer.toString();
  }
}

/// A titled group of texts on the list screen.
class ChurchTextGroup {
  final String title;
  final List<ChurchText> texts;

  const ChurchTextGroup(this.title, this.texts);
}
