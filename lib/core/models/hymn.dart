class Hymn {
  final int id;
  final String number;
  final String title;
  final String? key;
  final String lyrics;

  Hymn({
    required this.id,
    required this.number,
    required this.title,
    this.key,
    required this.lyrics,
  });

  factory Hymn.fromMap(Map<String, dynamic> map) => Hymn(
        id: map['id'] as int,
        number: map['number'] as String,
        title: map['title'] as String,
        key: map['key'] as String?,
        lyrics: map['lyrics'] as String,
      );
}
