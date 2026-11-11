import 'package:shared_preferences/shared_preferences.dart';
import '../models/hymn_list.dart';

export '../models/hymn_list.dart';

/// Stores the user's hymn lists on the device.
///
/// They are a handful of names and numbers, so they live in
/// SharedPreferences like the reading plan and the streak — no database
/// table to migrate — and they travel with the backup.
class HymnListService {
  static const storageKey = 'hymnLists.v1';

  static Future<List<HymnList>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return HymnListCodec.decode(prefs.getString(storageKey));
  }

  static Future<void> _save(List<HymnList> lists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, HymnListCodec.encode(lists));
  }

  static Future<HymnList?> get(String id) async {
    for (final list in await getAll()) {
      if (list.id == id) return list;
    }
    return null;
  }

  static Future<HymnList> create(String name, {List<String> numbers = const []}) async {
    final lists = await getAll();
    final list = HymnList(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      numbers: numbers,
    );
    // Newest first: the list being prepared is the one opened next.
    await _save([list, ...lists]);
    return list;
  }

  static Future<void> _update(String id, HymnList Function(HymnList) change) async {
    final lists = await getAll();
    await _save([for (final list in lists) list.id == id ? change(list) : list]);
  }

  static Future<void> rename(String id, String name) =>
      _update(id, (list) => list.copyWith(name: name.trim()));

  static Future<void> setNumbers(String id, List<String> numbers) =>
      _update(id, (list) => list.copyWith(numbers: numbers));

  /// Returns false when the hymn was already in the list.
  static Future<bool> addHymn(String id, String number) async {
    var added = false;
    await _update(id, (list) {
      added = !list.numbers.contains(number);
      return list.copyWith(numbers: HymnListCodec.withHymn(list.numbers, number));
    });
    return added;
  }

  static Future<void> delete(String id) async {
    final lists = await getAll();
    await _save(lists.where((list) => list.id != id).toList());
  }
}
