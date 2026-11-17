/// Verses of comfort and encouragement. The verse of the day is drawn from
/// this list (see [ComfortVerses.indexFor]) rather than walking through the
/// Bible in order. References only: the text comes from the Bible database.
class ComfortVerse {
  final String book;
  final int chapter;
  final int verse;
  const ComfortVerse(this.book, this.chapter, this.verse);
}

class ComfortVerses {
  static const all = <ComfortVerse>[
    ComfortVerse('Josué', 1, 9),
    ComfortVerse('Deutéronome', 31, 6),
    ComfortVerse('Deutéronome', 31, 8),
    ComfortVerse('Exode', 14, 14),
    ComfortVerse('Exode', 33, 14),
    ComfortVerse('Nombres', 6, 24),
    ComfortVerse('Nombres', 6, 26),
    ComfortVerse('Esaïe', 12, 2),
    ComfortVerse('Esaïe', 26, 3),
    ComfortVerse('Esaïe', 30, 15),
    ComfortVerse('Esaïe', 35, 4),
    ComfortVerse('Esaïe', 40, 29),
    ComfortVerse('Esaïe', 40, 31),
    ComfortVerse('Esaïe', 41, 10),
    ComfortVerse('Esaïe', 41, 13),
    ComfortVerse('Esaïe', 43, 1),
    ComfortVerse('Esaïe', 43, 2),
    ComfortVerse('Esaïe', 46, 4),
    ComfortVerse('Esaïe', 49, 15),
    ComfortVerse('Esaïe', 54, 10),
    ComfortVerse('Esaïe', 55, 12),
    ComfortVerse('Esaïe', 66, 13),
    ComfortVerse('Jérémie', 17, 7),
    ComfortVerse('Jérémie', 29, 11),
    ComfortVerse('Jérémie', 31, 3),
    ComfortVerse('Jérémie', 33, 3),
    ComfortVerse('Lamentations', 3, 22),
    ComfortVerse('Lamentations', 3, 23),
    ComfortVerse('Lamentations', 3, 25),
    ComfortVerse('Michée', 7, 8),
    ComfortVerse('Nahum', 1, 7),
    ComfortVerse('Sophonie', 3, 17),
    ComfortVerse('Psaumes', 9, 10),
    ComfortVerse('Psaumes', 16, 8),
    ComfortVerse('Psaumes', 16, 11),
    ComfortVerse('Psaumes', 18, 3),
    ComfortVerse('Psaumes', 23, 1),
    ComfortVerse('Psaumes', 23, 4),
    ComfortVerse('Psaumes', 25, 5),
    ComfortVerse('Psaumes', 27, 1),
    ComfortVerse('Psaumes', 27, 14),
    ComfortVerse('Psaumes', 28, 7),
    ComfortVerse('Psaumes', 29, 11),
    ComfortVerse('Psaumes', 30, 5),
    ComfortVerse('Psaumes', 31, 24),
    ComfortVerse('Psaumes', 32, 8),
    ComfortVerse('Psaumes', 33, 20),
    ComfortVerse('Psaumes', 34, 5),
    ComfortVerse('Psaumes', 34, 18),
    ComfortVerse('Psaumes', 34, 19),
    ComfortVerse('Psaumes', 37, 5),
    ComfortVerse('Psaumes', 37, 7),
    ComfortVerse('Psaumes', 40, 2),
    ComfortVerse('Psaumes', 46, 2),
    ComfortVerse('Psaumes', 50, 15),
    ComfortVerse('Psaumes', 55, 22),
    ComfortVerse('Psaumes', 56, 4),
    ComfortVerse('Psaumes', 62, 2),
    ComfortVerse('Psaumes', 71, 5),
    ComfortVerse('Psaumes', 73, 26),
    ComfortVerse('Psaumes', 86, 5),
    ComfortVerse('Psaumes', 91, 1),
    ComfortVerse('Psaumes', 91, 2),
    ComfortVerse('Psaumes', 91, 11),
    ComfortVerse('Psaumes', 94, 19),
    ComfortVerse('Psaumes', 100, 5),
    ComfortVerse('Psaumes', 103, 13),
    ComfortVerse('Psaumes', 116, 7),
    ComfortVerse('Psaumes', 118, 6),
    ComfortVerse('Psaumes', 119, 50),
    ComfortVerse('Psaumes', 119, 76),
    ComfortVerse('Psaumes', 119, 105),
    ComfortVerse('Psaumes', 119, 114),
    ComfortVerse('Psaumes', 121, 2),
    ComfortVerse('Psaumes', 121, 7),
    ComfortVerse('Psaumes', 126, 5),
    ComfortVerse('Psaumes', 130, 5),
    ComfortVerse('Psaumes', 138, 3),
    ComfortVerse('Psaumes', 139, 10),
    ComfortVerse('Psaumes', 143, 8),
    ComfortVerse('Psaumes', 145, 18),
    ComfortVerse('Psaumes', 147, 3),
    ComfortVerse('Proverbes', 3, 5),
    ComfortVerse('Proverbes', 3, 6),
    ComfortVerse('Proverbes', 18, 10),
    ComfortVerse('Matthieu', 5, 4),
    ComfortVerse('Matthieu', 6, 34),
    ComfortVerse('Matthieu', 7, 7),
    ComfortVerse('Matthieu', 10, 31),
    ComfortVerse('Matthieu', 11, 28),
    ComfortVerse('Matthieu', 11, 29),
    ComfortVerse('Luc', 1, 37),
    ComfortVerse('Luc', 12, 7),
    ComfortVerse('Luc', 12, 32),
    ComfortVerse('Jean', 3, 16),
    ComfortVerse('Jean', 10, 28),
    ComfortVerse('Jean', 14, 1),
    ComfortVerse('Jean', 14, 18),
    ComfortVerse('Jean', 14, 27),
    ComfortVerse('Jean', 15, 9),
    ComfortVerse('Jean', 16, 33),
    ComfortVerse('Romains', 5, 8),
    ComfortVerse('Romains', 8, 1),
    ComfortVerse('Romains', 8, 18),
    ComfortVerse('Romains', 8, 28),
    ComfortVerse('Romains', 8, 31),
    ComfortVerse('Romains', 8, 37),
    ComfortVerse('Romains', 12, 12),
    ComfortVerse('Romains', 15, 13),
    ComfortVerse('1 Corinthiens', 10, 13),
    ComfortVerse('1 Corinthiens', 15, 58),
    ComfortVerse('2 Corinthiens', 1, 3),
    ComfortVerse('2 Corinthiens', 4, 8),
    ComfortVerse('2 Corinthiens', 4, 16),
    ComfortVerse('2 Corinthiens', 12, 9),
    ComfortVerse('Galates', 6, 9),
    ComfortVerse('Philippiens', 1, 6),
    ComfortVerse('Philippiens', 4, 4),
    ComfortVerse('Philippiens', 4, 6),
    ComfortVerse('Philippiens', 4, 7),
    ComfortVerse('Philippiens', 4, 13),
    ComfortVerse('Philippiens', 4, 19),
    ComfortVerse('1 Thessaloniciens', 5, 11),
    ComfortVerse('2 Thessaloniciens', 3, 3),
    ComfortVerse('2 Timothée', 1, 7),
    ComfortVerse('Hébreux', 4, 16),
    ComfortVerse('Hébreux', 11, 1),
    ComfortVerse('Hébreux', 13, 6),
    ComfortVerse('Jacques', 1, 12),
    ComfortVerse('1 Pierre', 5, 7),
    ComfortVerse('1 Pierre', 5, 10),
    ComfortVerse('1 Jean', 4, 4),
    ComfortVerse('1 Jean', 4, 19),
    ComfortVerse('Révélation', 21, 4),
  ];

  static final _epoch = DateTime.utc(2024, 1, 1);
  static final _orders = <int, List<int>>{};

  /// Index in [all] of the verse for [day]. A different verse every day, in an
  /// order that looks random, with no repeat until the whole list has been
  /// shown (then the list is shuffled again). The same everywhere on a given
  /// day, so the widget and the home screen agree.
  static int indexFor(DateTime day) {
    final n = all.length;
    final dayNumber = DateTime.utc(day.year, day.month, day.day).difference(_epoch).inDays;
    final cycle = dayNumber >= 0 ? dayNumber ~/ n : -((-dayNumber + n - 1) ~/ n);
    final position = dayNumber - cycle * n;
    return _order(cycle)[position];
  }

  /// The shuffled order of one cycle. A first verse equal to the previous
  /// cycle's last one is moved on, so no verse shows two days in a row.
  static List<int> _order(int cycle) {
    return _orders.putIfAbsent(cycle, () {
      final order = _shuffled(cycle);
      final previousLast = _shuffledLast(cycle - 1);
      if (order.first == previousLast) {
        final first = order[0];
        order[0] = order[1];
        order[1] = first;
      }
      return order;
    });
  }

  static int _shuffledLast(int cycle) => _shuffled(cycle).last;

  /// Fisher–Yates shuffle driven by a small generator of our own, so every
  /// platform produces the same order.
  static List<int> _shuffled(int cycle) {
    final order = List<int>.generate(all.length, (i) => i);
    var state = (cycle * 2654435761 + 40503) & 0x7fffffff;
    int next() {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return state;
    }

    for (var i = order.length - 1; i > 0; i--) {
      final j = (next() >> 8) % (i + 1);
      final tmp = order[i];
      order[i] = order[j];
      order[j] = tmp;
    }
    return order;
  }

  /// A verse as it should be shown on its own: without the verse number of
  /// the Hebrew numbering that some Psalms carry ("(34 :6)"), the Psalm
  /// inscription ("Cantique de David.") or the closing "Pause" marker.
  static String cleanText(String book, String text) {
    var t = text.trim().replaceFirst(RegExp(r'^\(\d+\s*:\s*\d+\)\s*'), '');
    if (book == 'Psaumes') {
      t = t.replaceFirst(RegExp(r'^(?:Cantique|Psaume|De David|Prière|Chant|Au chef)[^.]{0,80}\.\s+'), '');
    }
    return t.replaceFirst(RegExp(r'\s*-?\s*Pause\.?\s*$'), '').trim();
  }
}
