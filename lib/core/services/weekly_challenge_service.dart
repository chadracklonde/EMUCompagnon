import 'package:shared_preferences/shared_preferences.dart';

/// Rotates through a fixed list of weekly spiritual-practice challenges.
/// Purely local and content-only (the theme list ships in code, not in
/// the database) — only the "done this week" flag is personal state,
/// stored in SharedPreferences.
class WeeklyChallengeService {
  static const List<String> _themes = [
    'Lisez l\'épître aux Philippiens en entier.',
    'Mémorisez un verset qui vous encourage particulièrement.',
    'Priez chaque jour pour une personne différente.',
    'Posez une question sur la foi à quelqu\'un de votre entourage.',
    'Rendez un service discret à un voisin ou un collègue.',
    'Jeûnez un repas ou une collation pour consacrer ce temps à la prière.',
    'Écrivez un mot d\'encouragement à quelqu\'un qui traverse une épreuve.',
    'Lisez un Psaume chaque jour de la semaine.',
    'Partagez avec un proche un verset qui vous a marqué récemment.',
    'Consacrez chaque jour 10 minutes de silence devant Dieu.',
    'Pardonnez, en paroles ou en pensée, à quelqu\'un qui vous a blessé.',
    'Invitez quelqu\'un à un culte ou à une étude biblique.',
  ];

  static final DateTime _epoch = DateTime(2024, 1, 1);

  /// A week index that only ever increases — stable regardless of year
  /// boundaries, unlike an ISO week number.
  static int _weekIndex([DateTime? now]) {
    final days = (now ?? DateTime.now()).difference(_epoch).inDays;
    return days ~/ 7;
  }

  static String getCurrentChallenge() {
    final index = _weekIndex() % _themes.length;
    return _themes[index];
  }

  static String _prefKey(int weekIndex) => 'weeklyChallenge.done.$weekIndex';

  static Future<bool> isCurrentCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey(_weekIndex())) ?? false;
  }

  static Future<void> setCurrentCompleted(bool done) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey(_weekIndex()), done);
  }
}
