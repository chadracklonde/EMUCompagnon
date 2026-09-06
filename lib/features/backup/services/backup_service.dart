import 'dart:convert';
import 'dart:ui';
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
///
/// Deliberately platform-agnostic (no dart:io): the export goes through
/// `XFile.fromData` (in-memory bytes), and the import reads
/// `PlatformFile.bytes` (requested via `withData: true`) rather than a
/// filesystem path — both work identically on mobile, desktop, and web,
/// where there is no real filesystem to read/write from directly.
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

  /// Builds the backup in memory and opens the native share sheet so the
  /// user can save it to Drive, Files, WhatsApp, email, etc. (or, on the
  /// web, trigger a browser download).
  Future<void> exportAndShare() async {
    final data = await _buildExportMap();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final file = XFile.fromData(
      utf8.encode(jsonStr),
      mimeType: 'application/json',
      name: 'emu_compagnon_sauvegarde_$stamp.json',
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
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
      withData: true, // always populate .bytes, on every platform
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return null;
    final content = utf8.decode(bytes);
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
