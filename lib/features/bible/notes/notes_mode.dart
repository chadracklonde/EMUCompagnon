import 'package:shared_preferences/shared_preferences.dart';

/// Les trois façons de lire une version qui a des notes.
enum NotesMode {
  /// Le texte seul, comme les autres versions.
  text,

  /// Le texte avec le début de chaque note sous son dernier verset.
  study,

  /// Les notes lues comme un commentaire, chaque verset rappelé en citation.
  notes;

  static const _key = 'bible.notesMode';

  /// Le dernier mode choisi ; [text] par défaut.
  static Future<NotesMode> load() async {
    try {
      final name = (await SharedPreferences.getInstance()).getString(_key);
      return NotesMode.values
          .firstWhere((m) => m.name == name, orElse: () => NotesMode.text);
    } catch (_) {
      return NotesMode.text;
    }
  }

  Future<void> save() async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key, name);
    } catch (_) {}
  }
}
