import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the last Bible chapter and last hymn opened, so the app can
/// offer a quick "Reprendre la lecture" shortcut on the home screens.
class ReadingHistoryService {
  static const _kLastBook = 'reading.lastBibleBook';
  static const _kLastChapter = 'reading.lastBibleChapter';
  static const _kLastHymnNumber = 'reading.lastHymnNumber';
  static const _kLastHymnTitle = 'reading.lastHymnTitle';

  static Future<void> saveLastBibleRead(String book, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastBook, book);
    await prefs.setInt(_kLastChapter, chapter);
  }

  static Future<({String book, int chapter})?> getLastBibleRead() async {
    final prefs = await SharedPreferences.getInstance();
    final book = prefs.getString(_kLastBook);
    final chapter = prefs.getInt(_kLastChapter);
    if (book == null || chapter == null) return null;
    return (book: book, chapter: chapter);
  }

  static Future<void> saveLastHymnRead(String number, String title) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastHymnNumber, number);
    await prefs.setString(_kLastHymnTitle, title);
  }

  static Future<({String number, String title})?> getLastHymnRead() async {
    final prefs = await SharedPreferences.getInstance();
    final number = prefs.getString(_kLastHymnNumber);
    final title = prefs.getString(_kLastHymnTitle);
    if (number == null || title == null) return null;
    return (number: number, title: title);
  }
}
