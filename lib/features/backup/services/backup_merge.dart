/// Pure merge rules used when importing a backup into a device that
/// already holds some progress. No Flutter / database dependency, so they
/// can be unit-tested on their own (see test/backup_merge_test.dart).

/// The streak counters as stored in SharedPreferences.
class StreakState {
  final String? lastDate; // yyyy-MM-dd, or null if never opened
  final int current;
  final int longest;
  const StreakState({this.lastDate, this.current = 0, this.longest = 0});

  @override
  bool operator ==(Object other) =>
      other is StreakState &&
      other.lastDate == lastDate &&
      other.current == current &&
      other.longest == longest;

  @override
  int get hashCode => Object.hash(lastDate, current, longest);

  @override
  String toString() => 'StreakState($lastDate, $current, $longest)';
}

/// Union of two reading-plan progress lists ("0,1,2,5" — completed day
/// indices), so importing never un-checks something already read here.
/// Returns null when the result is empty. Malformed entries are ignored.
String? mergeReadingPlan(String? local, String? incoming) {
  final indices = <int>{};
  for (final raw in [local, incoming]) {
    if (raw == null || raw.isEmpty) continue;
    for (final part in raw.split(',')) {
      final n = int.tryParse(part.trim());
      if (n != null && n >= 0) indices.add(n);
    }
  }
  if (indices.isEmpty) return null;
  final sorted = indices.toList()..sort();
  return sorted.join(',');
}

/// Keeps the best of both devices: the longest streak ever reached, and the
/// current streak of whichever side was active most recently (the larger
/// value when both were last active the same day).
StreakState mergeStreak(StreakState local, StreakState incoming) {
  final longest =
      local.longest > incoming.longest ? local.longest : incoming.longest;

  final a = local.lastDate;
  final b = incoming.lastDate;
  String? lastDate;
  int current;
  if (a == null && b == null) {
    lastDate = null;
    current = local.current > incoming.current ? local.current : incoming.current;
  } else if (b == null || (a != null && a.compareTo(b) > 0)) {
    lastDate = a;
    current = local.current;
  } else if (a == null || a.compareTo(b) < 0) {
    lastDate = b;
    current = incoming.current;
  } else {
    lastDate = a; // same day on both sides
    current = local.current > incoming.current ? local.current : incoming.current;
  }
  if (current > longest) {
    return StreakState(lastDate: lastDate, current: current, longest: current);
  }
  return StreakState(lastDate: lastDate, current: current, longest: longest);
}
