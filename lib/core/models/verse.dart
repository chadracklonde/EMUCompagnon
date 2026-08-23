class Verse {
  final int id;
  final String book;
  final int bookNum;
  final int chapter;
  final int verse;
  final String text;
  final String version;

  Verse({
    required this.id,
    required this.book,
    required this.bookNum,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.version,
  });

  factory Verse.fromMap(Map<String, dynamic> map) => Verse(
        id: map['id'] as int,
        book: map['book'] as String,
        bookNum: map['book_num'] as int,
        chapter: map['chapter'] as int,
        verse: map['verse'] as int,
        text: map['text'] as String,
        version: map['version'] as String,
      );

  String get reference => '$book $chapter.$verse';
}
