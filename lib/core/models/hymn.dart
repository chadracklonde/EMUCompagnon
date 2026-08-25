class Hymn {
  final int id;
  final String number;
  final String title;
  final String? key;
  final String lyrics;
  /// URL or local asset path to a recorded melody, if one has been added
  /// for this hymn. Null for the vast majority today — no audio has been
  /// recorded/sourced yet; the player UI only appears when this is set.
  final String? audioUrl;

  Hymn({
    required this.id,
    required this.number,
    required this.title,
    this.key,
    required this.lyrics,
    this.audioUrl,
  });

  factory Hymn.fromMap(Map<String, dynamic> map) => Hymn(
        id: map['id'] as int,
        number: map['number'] as String,
        title: map['title'] as String,
        key: map['key'] as String?,
        lyrics: map['lyrics'] as String,
        audioUrl: map['audio_url'] as String?,
      );
}
