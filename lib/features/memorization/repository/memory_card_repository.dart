import '../../../core/database/db_helper.dart';
import '../../../core/models/memory_card.dart';

/// Stores and schedules the user's verse-memorization flashcards, using a
/// simplified version of the SM-2 spaced-repetition algorithm. Entirely
/// local (the `memory_cards` table is personal data, like notes and
/// highlights — never touched by a content refresh).
class MemoryCardRepository {
  static String _today() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String _plusDays(int days) {
    final d = DateTime.now().add(Duration(days: days));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<List<MemoryCard>> getAll() async {
    final db = await DbHelper.database;
    final rows = await db.query('memory_cards', orderBy: 'due_date ASC');
    return rows.map((r) => MemoryCard.fromMap(r)).toList();
  }

  /// Cards due for review today or earlier (overdue cards are not
  /// penalized further — they just show up until reviewed).
  Future<List<MemoryCard>> getDueToday() async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'memory_cards',
      where: 'due_date <= ?',
      whereArgs: [_today()],
      orderBy: 'due_date ASC',
    );
    return rows.map((r) => MemoryCard.fromMap(r)).toList();
  }

  Future<bool> isAlreadyAdded(String book, int chapter, int verse) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'memory_cards',
      where: 'book = ? AND chapter = ? AND verse = ?',
      whereArgs: [book, chapter, verse],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> addCard({
    required String book,
    required int chapter,
    required int verse,
    required String verseText,
    required String referenceLabel,
  }) async {
    final db = await DbHelper.database;
    await db.insert('memory_cards', {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'verse_text': verseText,
      'reference_label': referenceLabel,
      'ease_factor': 2.5,
      'interval_days': 1,
      'repetitions': 0,
      'due_date': _today(), // due immediately, so it shows up for review today
    });
  }

  Future<void> removeCard(int id) async {
    final db = await DbHelper.database;
    await db.delete('memory_cards', where: 'id = ?', whereArgs: [id]);
  }

  /// Applies a simplified SM-2 update after the user grades their recall
  /// of [card]. "Again" resets progress (common for a hard-forgotten
  /// verse); the other grades grow the interval while nudging the ease
  /// factor, clamped so a string of "hard" answers never drives it below
  /// a sane floor.
  Future<void> grade(MemoryCard card, RecallQuality quality) async {
    final db = await DbHelper.database;

    int repetitions = card.repetitions;
    int interval = card.intervalDays;
    double ease = card.easeFactor;

    if (quality == RecallQuality.again) {
      repetitions = 0;
      interval = 1;
      ease = (ease - 0.2).clamp(1.3, 2.8);
    } else {
      final easeDelta = switch (quality) {
        RecallQuality.hard => -0.15,
        RecallQuality.good => 0.0,
        RecallQuality.easy => 0.15,
        RecallQuality.again => 0.0, // unreachable, handled above
      };
      ease = (ease + easeDelta).clamp(1.3, 2.8);
      repetitions += 1;
      if (repetitions == 1) {
        interval = 1;
      } else if (repetitions == 2) {
        interval = 6;
      } else {
        interval = (interval * ease).round();
      }
      if (quality == RecallQuality.hard) {
        interval = (interval * 0.7).round().clamp(1, interval);
      } else if (quality == RecallQuality.easy) {
        interval = (interval * 1.3).round();
      }
    }
    if (interval < 1) interval = 1;

    await db.update(
      'memory_cards',
      {
        'ease_factor': ease,
        'interval_days': interval,
        'repetitions': repetitions,
        'due_date': _plusDays(interval),
      },
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }
}
