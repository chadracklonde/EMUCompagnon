enum BookmarkType { verse, hymn, dictionary }

class Bookmark {
  final int id;
  final BookmarkType type;
  final int refId;
  final String? note;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.type,
    required this.refId,
    this.note,
    required this.createdAt,
  });

  factory Bookmark.fromMap(Map<String, dynamic> map) => Bookmark(
        id: map['id'] as int,
        type: BookmarkType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => BookmarkType.verse,
        ),
        refId: map['ref_id'] as int,
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
