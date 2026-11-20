/// Une note de commentaire (par exemple de la Bible annotée).
///
/// [verse] vaut 0 pour une introduction de chapitre ou de section ; sinon la
/// note est rangée au **dernier** verset qu'elle commente : une note rangée
/// au verset 15 peut commenter les versets 14 et 15 ensemble.
class BibleNote {
  final String version;
  final String book;
  final int chapter;
  final int verse;

  /// Texte de la note dans le petit langage de balises décrit dans
  /// `NoteText` : p, i, b, h, ref, ul, li, br.
  final String html;

  const BibleNote({
    required this.version,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.html,
  });
}

/// Une note et les versets qu'elle couvre (de [start] à [end], inclus).
class NoteGroup {
  final int start;
  final int end;
  final String html;
  const NoteGroup({required this.start, required this.end, required this.html});

  bool covers(int verse) => verse >= start && verse <= end;

  /// « 14-15 » ou « 16 ».
  String get range => start == end ? '$start' : '$start-$end';
}

/// Les notes d'un chapitre : l'introduction éventuelle, puis les notes dans
/// l'ordre des versets.
class ChapterNotes {
  final List<String> intros;
  final List<NoteGroup> groups;
  const ChapterNotes({this.intros = const [], this.groups = const []});

  static const empty = ChapterNotes();
  bool get isEmpty => intros.isEmpty && groups.isEmpty;

  /// Range les notes brutes d'un chapitre de [verseCount] versets.
  ///
  /// Une note commente les versets qui suivent la note précédente, jusqu'à
  /// son propre verset. Un numéro hors du chapitre (faute de la source) est
  /// ramené au dernier verset ; deux notes sur le même verset restent deux
  /// groupes distincts, dans l'ordre de lecture.
  static ChapterNotes build(List<BibleNote> notes, {required int verseCount}) {
    if (notes.isEmpty || verseCount <= 0) return empty;
    final intros = <String>[];
    final keyed = <MapEntry<int, String>>[];
    for (final n in notes) {
      if (n.verse <= 0) {
        intros.add(n.html);
      } else {
        keyed
            .add(MapEntry(n.verse > verseCount ? verseCount : n.verse, n.html));
      }
    }
    // Tri stable : à numéro égal, l'ordre de lecture est conservé.
    final indexed = [for (var i = 0; i < keyed.length; i++) (i, keyed[i])];
    indexed.sort((a, b) {
      final c = a.$2.key.compareTo(b.$2.key);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    final groups = <NoteGroup>[];
    var next = 1;
    for (final (_, e) in indexed) {
      final end = e.key;
      final start = next <= end ? next : end;
      groups.add(NoteGroup(start: start, end: end, html: e.value));
      if (end + 1 > next) next = end + 1;
    }
    return ChapterNotes(intros: intros, groups: groups);
  }

  /// Les notes qui se terminent au verset [verse] (pour l'affichage Étude,
  /// où la note vient juste après son dernier verset).
  List<NoteGroup> endingAt(int verse) => [
        for (final g in groups)
          if (g.end == verse) g
      ];

  /// La note qui commente [verse], ou null.
  NoteGroup? coveringVerse(int verse) {
    for (final g in groups) {
      if (g.covers(verse)) return g;
    }
    return null;
  }
}


/// Une introduction de livre (ou une étude qui l'accompagne).
class BookIntro {
  final String id;
  final String title;
  final String html;
  const BookIntro({required this.id, required this.title, required this.html});
}
