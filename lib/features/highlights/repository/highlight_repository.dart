import 'package:sqflite/sqflite.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/bookmark.dart';
import '../../../core/models/highlight.dart';

class HighlightRepository {
  Future<VerseHighlight?> get(BookmarkType type, int refId) async {
    final db = await DbHelper.database;
    final rows = await db.query(
      'highlights',
      where: 'type = ? AND ref_id = ?',
      whereArgs: [type.name, refId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return VerseHighlight.fromMap(rows.first);
  }

  Future<Map<int, String>> getAllColorsFor(BookmarkType type) async {
    final db = await DbHelper.database;
    final rows = await db.query('highlights', where: 'type = ?', whereArgs: [type.name]);
    return {for (final r in rows) r['ref_id'] as int: r['color_hex'] as String};
  }

  Future<void> setColor(BookmarkType type, int refId, String colorHex) async {
    final db = await DbHelper.database;
    await db.insert(
      'highlights',
      {
        'type': type.name,
        'ref_id': refId,
        'color_hex': colorHex,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(BookmarkType type, int refId) async {
    final db = await DbHelper.database;
    await db.delete('highlights', where: 'type = ? AND ref_id = ?', whereArgs: [type.name, refId]);
  }
}
