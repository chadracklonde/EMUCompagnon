/// One question of the Bible quiz bank (`assets/quiz/quiz_fr.json`).
///
/// The bank is French-only and every answer can be checked against the
/// Louis Segond 1910 text that ships with the app. [category], [level] and
/// [testament] are editorial proposals used for filtering the quiz.
class BibleQuizQuestion {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String category;

  /// 1 = easy, 2 = medium, 3 = hard.
  final int level;

  /// `'AT'`, `'NT'` or `''` when undetermined.
  final String testament;

  /// Louis Segond references that support the answer (may be empty).
  final List<String> references;

  const BibleQuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.category,
    required this.level,
    required this.testament,
    this.references = const [],
  });

  factory BibleQuizQuestion.fromJson(Map<String, dynamic> json) {
    final options = (json['o'] as List).cast<String>();
    final correct = json['a'] as int;
    if (options.length < 2 || correct < 0 || correct >= options.length) {
      throw FormatException('Invalid quiz question ${json['id']}');
    }
    return BibleQuizQuestion(
      id: json['id'] as String,
      text: json['t'] as String,
      options: options,
      correctIndex: correct,
      category: (json['c'] as String?) ?? '',
      level: (json['n'] as int?) ?? 2,
      testament: (json['b'] as String?) ?? '',
      references: ((json['r'] as List?) ?? const []).cast<String>(),
    );
  }

  String get correctOption => options[correctIndex];
}
