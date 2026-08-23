import '../../../core/database/db_helper.dart';
import '../../../core/models/bookmark.dart';

class BookmarkRepository {
  Future<int> add(BookmarkType type, int refId, {String? note}) async {
    final db = await DbHelper.database;
    return db.insert('bookmarks', {
      'type': type.name,
      'ref_id': refId,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> remove(int id) async {
    final db = await DbHelper.database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> removeByRef(BookmarkType type, int refId) async {
    final db = await DbHelper.database;
    await db.delete(
      'bookmarks',
      where: 'type = ? AND ref_id = ?',
      whereArgs: [type.name, refId],
    );
  }

  /// Returns the bookmark id if [type]/[refId] is bookmarked, else null.
  Future<int?> findId(BookmarkType type, int refId) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'bookmarks',
      where: 'type = ? AND ref_id = ?',
      whereArgs: [type.name, refId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as int;
  }

  Future<bool> isBookmarked(BookmarkType type, int refId) async {
    return (await findId(type, refId)) != null;
  }

  /// Toggles the bookmark and returns the new state (true = now bookmarked).
  Future<bool> toggle(BookmarkType type, int refId, {String? note}) async {
    final existingId = await findId(type, refId);
    if (existingId != null) {
      await remove(existingId);
      return false;
    } else {
      await add(type, refId, note: note);
      return true;
    }
  }

  Future<List<Bookmark>> listByType(BookmarkType type) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'bookmarks',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => Bookmark.fromMap(r)).toList();
  }

  Future<List<Bookmark>> listAll() async {
    final db = await DbHelper.database;
    final rows = await db.query('bookmarks', orderBy: 'created_at DESC');
    return rows.map((r) => Bookmark.fromMap(r)).toList();
  }
}
