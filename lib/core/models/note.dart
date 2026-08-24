import 'bookmark.dart'; // reuses BookmarkType (verse/hymn/dictionary)

class VerseNote {
  final int id;
  final BookmarkType type;
  final int refId;
  final String noteText;
  final DateTime createdAt;
  final DateTime updatedAt;

  VerseNote({
    required this.id,
    required this.type,
    required this.refId,
    required this.noteText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VerseNote.fromMap(Map<String, dynamic> map) => VerseNote(
        id: map['id'] as int,
        type: BookmarkType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => BookmarkType.verse,
        ),
        refId: map['ref_id'] as int,
        noteText: map['note_text'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
