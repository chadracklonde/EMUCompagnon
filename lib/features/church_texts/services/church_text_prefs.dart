import 'package:shared_preferences/shared_preferences.dart';

/// What the reader keeps about the prayers and texts: the ones pinned to
/// the home screen, and where reading stopped in each.
class ChurchTextPrefs {
  static const pinnedKey = 'churchTexts.pinned';
  static const _positionPrefix = 'churchTexts.position.';

  /// Ids of the pinned texts, in the order they were pinned.
  static Future<List<String>> pinned() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(pinnedKey) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> isPinned(String id) async =>
      (await pinned()).contains(id);

  /// Pins or unpins [id]; returns whether it is pinned afterwards.
  static Future<bool> toggle(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = [...prefs.getStringList(pinnedKey) ?? const <String>[]];
    final nowPinned = !ids.remove(id);
    if (nowPinned) ids.add(id);
    await prefs.setStringList(pinnedKey, ids);
    return nowPinned;
  }

  /// Pinned ids after an import: the local ones, then any new one.
  static List<String> merge(List<String> local, List<String> incoming) => [
        ...local,
        for (final id in incoming)
          if (!local.contains(id)) id,
      ];

  /// Scroll offset where reading of [id] stopped (0 at the top).
  static Future<double> position(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('$_positionPrefix$id') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> savePosition(String id, double offset) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('$_positionPrefix$id', offset);
    } catch (_) {
      // Losing the reading position is harmless.
    }
  }
}
