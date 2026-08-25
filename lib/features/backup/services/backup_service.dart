import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/db_helper.dart';

class BackupSummary {
  final int bookmarks;
  final int notes;
  final int highlights;
  const BackupSummary({required this.bookmarks, required this.notes, required this.highlights});
}

/// Exports/imports the user's personal data (favorites, notes, highlight
/// colors) as a plain JSON file — a simple, no-account way to avoid
/// losing this data when switching phones or reinstalling the app.
/// Deliberately does NOT touch the Bible/hymns/dictionary content itself.
class BackupService {
  static const _formatVersion = 1;

  Future<Map<String, dynamic>> _buildExportMap() async {
    final db = await DbHelper.database;
    final bookmarks = await db.query('bookmarks');
    final notes = await db.query('notes');
    final highlights = await db.query('highlights');
    return {
      'format_version': _formatVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'ÉMU Compagnon',
      'bookmarks': bookmarks,
      'notes': notes,
      'highlights': highlights,
    };
  }

  /// Writes the backup to a temp file and opens the native share sheet
  /// so the user can save it to Drive, Files, WhatsApp, email, etc.
  Future<void> exportAndShare() async {
    final data = await _buildExportMap();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final tempDir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final file = File('${tempDir.path}/emu_compagnon_sauvegarde_$stamp.json');
    await file.writeAsBytes(utf8.encode(jsonStr), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Sauvegarde ÉMU Compagnon ($stamp)',
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      ),
    );
  }

  /// Lets the user pick a previously exported .json file and imports it.
  /// Returns null if the user cancelled the picker.
  Future<BackupSummary?> pickFileAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return null;
    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    return importFromJson(content);
  }

  Future<BackupSummary> importFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final db = await DbHelper.database;

    var bookmarkCount = 0;
    var noteCount = 0;
    var highlightCount = 0;

    final bookmarks = (data['bookmarks'] as List?) ?? [];
    for (final raw in bookmarks) {
      final b = Map<String, dynamic>.from(raw as Map);
      final existing = await db.query(
        'bookmarks',
        where: 'type = ? AND ref_id = ?',
        whereArgs: [b['type'], b['ref_id']],
      );
      if (existing.isEmpty) {
        await db.insert('bookmarks', {
          'type': b['type'],
          'ref_id': b['ref_id'],
          'note': b['note'],
          'created_at': b['created_at'] ?? DateTime.now().toIso8601String(),
        });
        bookmarkCount++;
      }
    }

    final notes = (data['notes'] as List?) ?? [];
    for (final raw in notes) {
      final n = Map<String, dynamic>.from(raw as Map);
      final existing = await db.query(
        'notes',
        where: 'type = ? AND ref_id = ? AND note_text = ?',
        whereArgs: [n['type'], n['ref_id'], n['note_text']],
      );
      if (existing.isEmpty) {
        await db.insert('notes', {
          'type': n['type'],
          'ref_id': n['ref_id'],
          'note_text': n['note_text'],
          'created_at': n['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': n['updated_at'] ?? DateTime.now().toIso8601String(),
        });
        noteCount++;
      }
    }

    final highlights = (data['highlights'] as List?) ?? [];
    for (final raw in highlights) {
      final h = Map<String, dynamic>.from(raw as Map);
      await db.insert(
        'highlights',
        {
          'type': h['type'],
          'ref_id': h['ref_id'],
          'color_hex': h['color_hex'],
          'created_at': h['created_at'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      highlightCount++;
    }

    return BackupSummary(bookmarks: bookmarkCount, notes: noteCount, highlights: highlightCount);
  }
}
