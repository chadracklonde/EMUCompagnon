import 'dart:convert';

/// A named, ordered set of hymns — typically the programme of a service.
///
/// Hymns are remembered by their printed number ("18"), not by a database
/// id: the number is what worship leaders use, and it stays the same when
/// the hymn content is updated.
class HymnList {
  final String id;
  final String name;
  final List<String> numbers;

  const HymnList({required this.id, required this.name, this.numbers = const []});

  HymnList copyWith({String? name, List<String>? numbers}) =>
      HymnList(id: id, name: name ?? this.name, numbers: numbers ?? this.numbers);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'numbers': numbers};

  static HymnList? fromJson(dynamic json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    final numbers = json['numbers'];
    if (id is! String || id.isEmpty || name is! String) return null;
    return HymnList(
      id: id,
      name: name,
      numbers: numbers is List ? numbers.whereType<String>().toList() : const [],
    );
  }
}

/// Pure rules for storing and combining hymn lists (no storage, no
/// Flutter), so they can be unit-tested on their own.
class HymnListCodec {
  static String encode(List<HymnList> lists) =>
      jsonEncode([for (final list in lists) list.toJson()]);

  /// Never throws: unreadable data gives no lists, and a malformed entry
  /// is skipped rather than losing the others.
  static List<HymnList> decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return [];
      return data.map(HymnList.fromJson).whereType<HymnList>().toList();
    } catch (_) {
      return [];
    }
  }

  /// Combines the lists of this device with those of an imported backup.
  /// Local lists are kept as they are; a list that exists only in the
  /// backup is added. Nothing here is ever removed or overwritten.
  static List<HymnList> merge(List<HymnList> local, List<HymnList> incoming) {
    final ids = {for (final list in local) list.id};
    return [
      ...local,
      for (final list in incoming)
        if (ids.add(list.id)) list,
    ];
  }

  /// [numbers] with [number] added at the end, unless already present.
  static List<String> withHymn(List<String> numbers, String number) =>
      numbers.contains(number) ? numbers : [...numbers, number];

  /// [numbers] with the item at [oldIndex] moved so that it ends up at
  /// position [newIndex].
  static List<String> moved(List<String> numbers, int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= numbers.length) return numbers;
    final result = [...numbers];
    final item = result.removeAt(oldIndex);
    result.insert(newIndex.clamp(0, result.length), item);
    return result;
  }
}
