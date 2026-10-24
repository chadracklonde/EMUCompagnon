import 'dart:convert';
import '../../../core/database/db_helper.dart';
import '../../../core/models/evening_examen_entry.dart';

/// A short daily "examen" in the Wesleyan tradition: a fixed set of
/// end-of-day reflection questions, answered once per day and kept
/// private and local. The question list itself lives in
/// [EveningExamenRepository.questions] (content, not personal data);
/// only the answers are stored.
class EveningExamenRepository {
  static const List<String> questions = [
    'Où ai-je vu Dieu à l\'œuvre aujourd\'hui ?',
    'Ai-je aimé mon prochain comme moi-même aujourd\'hui ?',
    'Qu\'est-ce qui m\'a éloigné de Dieu aujourd\'hui ?',
    'Pour quoi suis-je reconnaissant ce soir ?',
  ];

  static String _today() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<EveningExamenEntry?> getToday() async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'evening_examen_entries',
      where: 'entry_date = ?',
      whereArgs: [_today()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return EveningExamenEntry.fromMap(rows.first);
  }

  /// Creates today's entry, or overwrites it if the user already
  /// answered the examen today and comes back to edit their answers.
  Future<void> upsertToday(List<String> answers) async {
    final existing = await getToday();
    final db = await DbHelper.database;
    if (existing == null) {
      await db.insert('evening_examen_entries', {
        'entry_date': _today(),
        'answers': jsonEncode(answers),
      });
    } else {
      await db.update(
        'evening_examen_entries',
        {'answers': jsonEncode(answers)},
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
  }
}
