import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bible_quiz_question.dart';

/// Best score and counters of the Bible quiz, kept locally.
class BibleQuizStats {
  final int gamesPlayed;
  final int bestScorePercent;
  const BibleQuizStats({this.gamesPlayed = 0, this.bestScorePercent = 0});
}

/// Loads the bundled French Bible quiz bank and draws sessions from it.
///
/// Entirely offline. Questions already played are remembered (up to
/// [_maxSeen]) so a new session prefers questions not seen recently; once
/// the filtered pool is exhausted the memory is ignored for that session.
class BibleQuizService {
  static const String assetPath = 'assets/quiz/quiz_fr.json';
  static const int defaultSessionLength = 10;
  static const int _maxSeen = 600;
  static const _kSeen = 'bibleQuiz.seen';
  static const _kGames = 'bibleQuiz.games';
  static const _kBest = 'bibleQuiz.bestPercent';

  static List<BibleQuizQuestion>? _cache;

  /// Parses the bank JSON. Exposed for tests.
  static List<BibleQuizQuestion> parse(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    return (data['q'] as List)
        .map((e) => BibleQuizQuestion.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<List<BibleQuizQuestion>> loadAll({AssetBundle? bundle}) async {
    if (bundle == null && _cache != null) return _cache!;
    final source = await (bundle ?? rootBundle).loadString(assetPath);
    final all = parse(source);
    if (bundle == null) _cache = all;
    return all;
  }

  static List<BibleQuizQuestion> filter(
    List<BibleQuizQuestion> all, {
    String? testament,
    int? level,
  }) {
    return all
        .where((q) =>
            (testament == null || q.testament == testament) &&
            (level == null || q.level == level))
        .toList();
  }

  /// Draws up to [count] questions from the filtered pool, preferring those
  /// not in [seen].
  static List<BibleQuizQuestion> pick(
    List<BibleQuizQuestion> all, {
    int count = defaultSessionLength,
    String? testament,
    int? level,
    Set<String> seen = const {},
    Random? random,
  }) {
    final rng = random ?? Random();
    final pool = filter(all, testament: testament, level: level);
    var fresh = pool.where((q) => !seen.contains(q.id)).toList();
    if (fresh.length < count) fresh = pool;
    fresh.shuffle(rng);
    return fresh.take(min(count, fresh.length)).toList();
  }

  static Future<Set<String>> loadSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kSeen) ?? const []).toSet();
  }

  static Future<void> markSeen(Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final list = [...(prefs.getStringList(_kSeen) ?? const <String>[])];
    for (final id in ids) {
      list.remove(id);
      list.add(id);
    }
    final trimmed =
        list.length > _maxSeen ? list.sublist(list.length - _maxSeen) : list;
    await prefs.setStringList(_kSeen, trimmed);
  }

  static Future<BibleQuizStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    return BibleQuizStats(
      gamesPlayed: prefs.getInt(_kGames) ?? 0,
      bestScorePercent: prefs.getInt(_kBest) ?? 0,
    );
  }

  static Future<BibleQuizStats> recordResult(int score, int total) async {
    final prefs = await SharedPreferences.getInstance();
    final games = (prefs.getInt(_kGames) ?? 0) + 1;
    final percent = total == 0 ? 0 : (score * 100 / total).round();
    final best = max(prefs.getInt(_kBest) ?? 0, percent);
    await prefs.setInt(_kGames, games);
    await prefs.setInt(_kBest, best);
    return BibleQuizStats(gamesPlayed: games, bestScorePercent: best);
  }
}
