import '../../../core/database/db_helper.dart';
import '../../../core/models/journal_entry.dart';

/// Private prayer/gratitude journal — purely local notes with no
/// particular structure beyond a date and free text, intentionally never
/// synced or shared (unlike notes tied to a verse/hymn, these are
/// personal reflection, not reference material).
class JournalRepository {
  static String _today() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<List<JournalEntry>> getAll() async {
    final db = await DbHelper.database;
    final rows = await db.query('journal_entries', orderBy: 'entry_date DESC, id DESC');
    return rows.map((r) => JournalEntry.fromMap(r)).toList();
  }

  Future<void> add(String content) async {
    final db = await DbHelper.database;
    await db.insert('journal_entries', {
      'entry_date': _today(),
      'content': content,
    });
  }

  Future<void> update(int id, String content) async {
    final db = await DbHelper.database;
    await db.update('journal_entries', {'content': content}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> remove(int id) async {
    final db = await DbHelper.database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }
}
