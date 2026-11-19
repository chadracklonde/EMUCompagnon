import 'package:flutter_test/flutter_test.dart';
import 'package:emu_compagnon/core/services/notification_service.dart';
import 'package:emu_compagnon/features/reading_plan/services/reading_plan_service.dart';
import 'package:emu_compagnon/features/reading_plan/services/reading_reminder.dart';

void main() {
  final chapters = [
    for (var i = 0; i < 6; i++)
      PlanChapter(index: i, book: 'Genèse', chapter: i + 1, verses: 10),
  ];

  ReadingPlan planWith(Set<int> completed) => ReadingPlan(
        allChapters: chapters,
        baseline: const {},
        completed: completed,
        days: ReadingPlanBuilder.split(chapters, 3),
      );

  test('the reminder names the next portion to read', () {
    expect(ReadingReminder.bodyFor(planWith({})), 'Lecture du jour : Genèse 1–2.');
    expect(ReadingReminder.bodyFor(planWith({0, 1})), 'Lecture du jour : Genèse 3–4.');
    // A day counts as read only when all its chapters are.
    expect(ReadingReminder.bodyFor(planWith({0})), 'Lecture du jour : Genèse 1–2.');
  });

  test('a finished plan falls back to the generic reminder', () {
    expect(
      ReadingReminder.bodyFor(planWith({0, 1, 2, 3, 4, 5})),
      NotificationService.defaultReminderBody,
    );
  });
}
