class MemoryCard {
  final int id;
  final String book;
  final int chapter;
  final int verse;
  final String verseText;
  final String referenceLabel;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final String dueDate; // ISO date (yyyy-MM-dd)

  const MemoryCard({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.verseText,
    required this.referenceLabel,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueDate,
  });

  factory MemoryCard.fromMap(Map<String, dynamic> map) {
    return MemoryCard(
      id: map['id'] as int,
      book: map['book'] as String,
      chapter: map['chapter'] as int,
      verse: map['verse'] as int,
      verseText: map['verse_text'] as String,
      referenceLabel: map['reference_label'] as String,
      easeFactor: (map['ease_factor'] as num).toDouble(),
      intervalDays: map['interval_days'] as int,
      repetitions: map['repetitions'] as int,
      dueDate: map['due_date'] as String,
    );
  }
}

/// How well the user recalled a card — drives the next review interval.
enum RecallQuality { again, hard, good, easy }
