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

  // Chaque recueil garde son dernier cantique (le même numéro n'est pas le
  // même cantique d'un recueil à l'autre). Les Chants de Victoire gardent les
  // clés d'origine.
  static String _numberKey(String hymnal) =>
      hymnal == 'CV' ? _kLastHymnNumber : '$_kLastHymnNumber.$hymnal';
  static String _titleKey(String hymnal) =>
      hymnal == 'CV' ? _kLastHymnTitle : '$_kLastHymnTitle.$hymnal';

  static Future<void> saveLastHymnRead(String number, String title, {String hymnal = 'CV'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_numberKey(hymnal), number);
    await prefs.setString(_titleKey(hymnal), title);
  }

  static Future<({String number, String title})?> getLastHymnRead({String hymnal = 'CV'}) async {
    final prefs = await SharedPreferences.getInstance();
    final number = prefs.getString(_numberKey(hymnal));
    final title = prefs.getString(_titleKey(hymnal));
    if (number == null || title == null) return null;
    return (number: number, title: title);
  }
}
