import 'dart:convert';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/db_helper.dart';
import 'backup_merge.dart';

class BackupSummary {
  final int bookmarks;
  final int notes;
  final int highlights;
  final int memoryCards;
  final int journalEntries;
  final int examenEntries;
  const BackupSummary({
    required this.bookmarks,
    required this.notes,
    required this.highlights,
    this.memoryCards = 0,
    this.journalEntries = 0,
    this.examenEntries = 0,
  });
}

/// Exports/imports the user's personal data (favorites, notes, highlight
/// colors, memorization cards, prayer journal, evening examen, and the
/// reading-plan / streak / quiz / weekly-challenge progress) as a plain JSON file — a simple, no-account way to avoid
/// losing this data when switching phones or reinstalling the app.
/// Deliberately does NOT touch the Bible/hymns/dictionary content itself.
///
/// Deliberately platform-agnostic (no dart:io): the export goes through
/// `XFile.fromData` (in-memory bytes), and the import reads
/// `PlatformFile.bytes` (requested via `withData: true`) rather than a
/// filesystem path — both work identically on mobile, desktop, and web,
/// where there is no real filesystem to read/write from directly.
class BackupService {
  // Version 2 adds memory_cards, journal_entries, evening_examen_entries and
  // the SharedPreferences-based progress. A version 1 file (without those
  // keys) is still imported normally.
  static const _formatVersion = 2;

  // SharedPreferences keys owned by other services — keep in sync with
  // ReadingPlanService, StreakService, DailyQuizService and
  // WeeklyChallengeService (their constants are private).
  static const _kReadingPlan = 'readingPlan.completedIndices';
  static const _kStreakLast = 'streak.lastActiveDate';
  static const _kStreakCurrent = 'streak.current';
  static const _kStreakLongest = 'streak.longest';
  static const _kQuizPrefix = 'dailyQuiz.result.';
  static const _kChallengePrefix = 'weeklyChallenge.done.';

  Future<Map<String, dynamic>> _buildExportMap() async {
    final db = await DbHelper.database;
    final bookmarks = await db.query('bookmarks');
    final notes = await db.query('notes');
    final highlights = await db.query('highlights');
    final memoryCards = await db.query('memory_cards');
    final journal = await db.query('journal_entries');
    final examen = await db.query('evening_examen_entries');

    final prefs = await SharedPreferences.getInstance();
    final quizResults = <String, String>{
      for (final k in prefs.getKeys())
        if (k.startsWith(_kQuizPrefix) && prefs.getString(k) != null)
          k.substring(_kQuizPrefix.length): prefs.getString(k)!,
    };
    final challengesDone = <String>[
      for (final k in prefs.getKeys())
        if (k.startsWith(_kChallengePrefix) && prefs.getBool(k) == true)
          k.substring(_kChallengePrefix.length),
    ];
    return {
      'format_version': _formatVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'ÉMU Compagnon',
      'bookmarks': bookmarks,
      'notes': notes,
      'highlights': highlights,
      'memory_cards': memoryCards,
      'journal_entries': journal,
      'evening_examen_entries': examen,
      'progress': {
        'reading_plan': prefs.getString(_kReadingPlan),
        'streak': {
          'last_date': prefs.getString(_kStreakLast),
          'current': prefs.getInt(_kStreakCurrent) ?? 0,
          'longest': prefs.getInt(_kStreakLongest) ?? 0,
        },
        'quiz_results': quizResults,
        'weekly_challenges_done': challengesDone,
      },
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

    final extra = await _importPersonalExtras(db, data);

    return BackupSummary(
      bookmarks: bookmarkCount,
      notes: noteCount,
      highlights: highlightCount,
      memoryCards: extra.memoryCards,
      journalEntries: extra.journalEntries,
      examenEntries: extra.examenEntries,
    );
  }

  static String? _str(dynamic v) => v is String && v.isNotEmpty ? v : null;
  static int? _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);

  /// Imports the data added in backup format 2. Every entry is validated
  /// and a malformed one is skipped rather than failing the whole import;
  /// existing local rows are never overwritten or duplicated. All database
  /// writes happen in one transaction, so a failure leaves nothing half-done.
  Future<({int memoryCards, int journalEntries, int examenEntries})> _importPersonalExtras(
    Database db,
    Map<String, dynamic> data,
  ) async {
    var cards = 0;
    var journal = 0;
    var examen = 0;

    await db.transaction((txn) async {
      for (final raw in (data['memory_cards'] as List?) ?? const []) {
        if (raw is! Map) continue;
        final c = Map<String, dynamic>.from(raw);
        final book = _str(c['book']);
        final chapter = _int(c['chapter']);
        final verse = _int(c['verse']);
        final text = _str(c['verse_text']);
        final label = _str(c['reference_label']);
        final due = _str(c['due_date']);
        if (book == null || chapter == null || verse == null || text == null ||
            label == null || due == null) {
          continue;
        }
        final existing = await txn.query(
          'memory_cards',
          where: 'book = ? AND chapter = ? AND verse = ?',
          whereArgs: [book, chapter, verse],
          limit: 1,
        );
        if (existing.isNotEmpty) continue;
        await txn.insert('memory_cards', {
          'book': book,
          'chapter': chapter,
          'verse': verse,
          'verse_text': text,
          'reference_label': label,
          'ease_factor': (c['ease_factor'] is num) ? (c['ease_factor'] as num).toDouble() : 2.5,
          'interval_days': _int(c['interval_days']) ?? 1,
          'repetitions': _int(c['repetitions']) ?? 0,
          'due_date': due,
          'created_at': _str(c['created_at']) ?? DateTime.now().toIso8601String(),
        });
        cards++;
      }

      for (final raw in (data['journal_entries'] as List?) ?? const []) {
        if (raw is! Map) continue;
        final j = Map<String, dynamic>.from(raw);
        final date = _str(j['entry_date']);
        final content = _str(j['content']);
        if (date == null || content == null) continue;
        final existing = await txn.query(
          'journal_entries',
          where: 'entry_date = ? AND content = ?',
          whereArgs: [date, content],
          limit: 1,
        );
        if (existing.isNotEmpty) continue;
        await txn.insert('journal_entries', {
          'entry_date': date,
          'content': content,
          'created_at': _str(j['created_at']) ?? DateTime.now().toIso8601String(),
        });
        journal++;
      }

      for (final raw in (data['evening_examen_entries'] as List?) ?? const []) {
        if (raw is! Map) continue;
        final e = Map<String, dynamic>.from(raw);
        final date = _str(e['entry_date']);
        final answers = _str(e['answers']);
        if (date == null || answers == null) continue;
        // One examen per day (UNIQUE entry_date): keep what is already here.
        final existing = await txn.query(
          'evening_examen_entries',
          where: 'entry_date = ?',
          whereArgs: [date],
          limit: 1,
        );
        if (existing.isNotEmpty) continue;
        await txn.insert('evening_examen_entries', {
          'entry_date': date,
          'answers': answers,
          'created_at': _str(e['created_at']) ?? DateTime.now().toIso8601String(),
        });
        examen++;
      }
    });

    await _importProgress(data['progress']);
    return (memoryCards: cards, journalEntries: journal, examenEntries: examen);
  }

  /// Merges the SharedPreferences-based progress (never lowers anything
  /// the user already has on this device).
  Future<void> _importProgress(dynamic progress) async {
    if (progress is! Map) return;
    final prefs = await SharedPreferences.getInstance();

    final plan = mergeReadingPlan(
      prefs.getString(_kReadingPlan),
      _str(progress['reading_plan']),
    );
    if (plan != null) await prefs.setString(_kReadingPlan, plan);

    final s = progress['streak'];
    if (s is Map) {
      final merged = mergeStreak(
        StreakState(
          lastDate: prefs.getString(_kStreakLast),
          current: prefs.getInt(_kStreakCurrent) ?? 0,
          longest: prefs.getInt(_kStreakLongest) ?? 0,
        ),
        StreakState(
          lastDate: _str(s['last_date']),
          current: _int(s['current']) ?? 0,
          longest: _int(s['longest']) ?? 0,
        ),
      );
      if (merged.lastDate != null) await prefs.setString(_kStreakLast, merged.lastDate!);
      await prefs.setInt(_kStreakCurrent, merged.current);
      await prefs.setInt(_kStreakLongest, merged.longest);
    }

    final quiz = progress['quiz_results'];
    if (quiz is Map) {
      for (final entry in quiz.entries) {
        final key = '$_kQuizPrefix${entry.key}';
        if (entry.value is String && prefs.getString(key) == null) {
          await prefs.setString(key, entry.value as String);
        }
      }
    }

    final challenges = progress['weekly_challenges_done'];
    if (challenges is List) {
      for (final week in challenges) {
        if (week is String && week.isNotEmpty) {
          await prefs.setBool('$_kChallengePrefix$week', true);
        }
      }
    }
  }
}
