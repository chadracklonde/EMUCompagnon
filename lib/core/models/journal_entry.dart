class JournalEntry {
  final int id;
  final String entryDate; // ISO date (yyyy-MM-dd)
  final String content;
  final String createdAt;

  const JournalEntry({
    required this.id,
    required this.entryDate,
    required this.content,
    required this.createdAt,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int,
      entryDate: map['entry_date'] as String,
      content: map['content'] as String,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
