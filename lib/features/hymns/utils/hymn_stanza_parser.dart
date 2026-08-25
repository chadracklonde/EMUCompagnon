class HymnStanza {
  final String label; // e.g. "1", "2", "Cœur", "Refrain"
  final String body;
  final bool isRefrain;

  const HymnStanza({required this.label, required this.body, this.isRefrain = false});
}

/// Splits raw hymn lyrics (stored with every line separated by a blank
/// line) into distinct stanzas, detected via numbered markers ("1.", "2.")
/// or refrain markers ("Cœur", "Chœur", "Refrain"). Any leading line that
/// isn't lyrics at all (a lone musical key like "(mi bémol)") is kept as
/// a separate leading fragment, not a stanza.
class HymnStanzaParser {
  static final RegExp _numberedMarker = RegExp(r'^(\d+)\.\s*(.*)$');
  static final RegExp _refrainMarker =
      RegExp(r'^(Cœur|Choeur|Chœur|Refrain)\s*:?\s*(.*)$', caseSensitive: false);
  static final RegExp _keyLine = RegExp(r'^\(.+\)$');

  static List<HymnStanza> parse(String lyrics) {
    final rawLines = lyrics
        .split('\n\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final stanzas = <HymnStanza>[];
    String? currentLabel;
    bool currentIsRefrain = false;
    final currentBody = StringBuffer();

    void flush() {
      if (currentLabel != null && currentBody.isNotEmpty) {
        stanzas.add(HymnStanza(
          label: currentLabel!,
          body: currentBody.toString().trim(),
          isRefrain: currentIsRefrain,
        ));
      }
      currentBody.clear();
    }

    for (final line in rawLines) {
      // Skip a lone musical-key line like "(mi bémol)" entirely — it's
      // already shown separately in the screen header.
      if (_keyLine.hasMatch(line) && stanzas.isEmpty && currentLabel == null) {
        continue;
      }

      final numMatch = _numberedMarker.firstMatch(line);
      final refMatch = _refrainMarker.firstMatch(line);

      if (numMatch != null) {
        flush();
        currentLabel = numMatch.group(1);
        currentIsRefrain = false;
        final rest = numMatch.group(2) ?? '';
        if (rest.isNotEmpty) currentBody.writeln(rest);
      } else if (refMatch != null) {
        flush();
        currentLabel = _capitalize(refMatch.group(1)!);
        currentIsRefrain = true;
        final rest = refMatch.group(2) ?? '';
        if (rest.isNotEmpty) currentBody.writeln(rest);
      } else {
        if (currentLabel == null) {
          // No marker seen yet — start an unlabeled first stanza so no
          // content is silently dropped.
          currentLabel = '';
        }
        currentBody.writeln(line);
      }
    }
    flush();

    if (stanzas.isEmpty) {
      // No markers detected at all: fall back to the whole text as one
      // block, so nothing is ever lost.
      return [HymnStanza(label: '', body: lyrics.replaceAll('\n\n', '\n').trim())];
    }
    return stanzas;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}
