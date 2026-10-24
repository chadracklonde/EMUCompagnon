/// One multiple-choice question of the daily quiz: "which definition
/// matches this term?". [options] always has 4 entries and
/// [correctOptionIndex] points at the right one.
class QuizQuestion {
  final String term;
  final List<String> options;
  final int correctOptionIndex;

  const QuizQuestion({
    required this.term,
    required this.options,
    required this.correctOptionIndex,
  });
}
