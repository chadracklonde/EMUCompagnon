class DictionaryEntry {
  final int id;
  final String term;
  final String definition;
  final List<String> relatedReferences;

  DictionaryEntry({
    required this.id,
    required this.term,
    required this.definition,
    required this.relatedReferences,
  });

  factory DictionaryEntry.fromMap(Map<String, dynamic> map) {
    final raw = map['related_verses'] as String?;
    final refs = (raw == null || raw.isEmpty)
        ? <String>[]
        : raw.split(';').map((s) => s.trim()).toList();
    return DictionaryEntry(
      id: map['id'] as int,
      term: map['term'] as String,
      definition: map['definition'] as String,
      relatedReferences: refs,
    );
  }
}
