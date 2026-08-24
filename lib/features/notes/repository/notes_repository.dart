import '../../../core/database/db_helper.dart';
import '../../../core/models/bookmark.dart';
import '../../../core/models/note.dart';

class NotesRepository {
  Future<List<VerseNote>> listFor(BookmarkType type, int refId) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'notes',
      where: 'type = ? AND ref_id = ?',
      whereArgs: [type.name, refId],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => VerseNote.fromMap(r)).toList();
  }

  Future<List<VerseNote>> listAll(BookmarkType type) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'notes',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'updated_at DESC',
    );
    return rows.map((r) => VerseNote.fromMap(r)).toList();
  }

  Future<int> add(BookmarkType type, int refId, String text) async {
    final db = await DbHelper.database;
    final now = DateTime.now().toIso8601String();
    return db.insert('notes', {
      'type': type.name,
      'ref_id': refId,
      'note_text': text,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> update(int id, String text) async {
    final db = await DbHelper.database;
    await db.update(
      'notes',
      {'note_text': text, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DbHelper.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
