import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../about/screens/about_screen.dart';
import '../../daily_quiz/screens/daily_quiz_screen.dart';
import '../../dictionary/screens/dictionary_screen.dart';
import '../../evening_examen/screens/evening_examen_screen.dart';
import '../../favorites/screens/favorites_screen.dart';
import '../../journal/screens/journal_screen.dart';
import '../../memorization/screens/memorization_screen.dart';
import '../../reading_plan/screens/reading_plan_screen.dart';
import '../../search/screens/global_search_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../weekly_challenge/screens/weekly_challenge_screen.dart';

/// Fifth tab ("Plus"): everything that is not one of the four main
/// destinations — dictionary, favourites, spiritual-life tools, settings
/// and about. Keeps the bottom bar at five items.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppSettings>().locale;
    String t(String key) => AppStrings.t(key, locale);
    void open(Widget screen) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => screen),
        );

    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      appBar: AppBar(title: Text(t('nav_more'))),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            SectionTitle(t('section_library')),
            AppRowGroup(rows: [
              AppRow(
                icon: Icons.auto_stories_outlined,
                title: t('dictionary_full'),
                onTap: () => open(const DictionaryScreen()),
              ),
              AppRow(
                icon: Icons.star_outline,
                title: t('nav_favorites'),
                onTap: () => open(const FavoritesScreen()),
              ),
              AppRow(
                icon: Icons.search,
                title: t('search'),
                onTap: () => open(const GlobalSearchScreen()),
              ),
            ]),
            const SizedBox(height: 24),
            SectionTitle(t('section_spiritual_life')),
            AppRowGroup(rows: [
              AppRow(
                icon: Icons.event_note_outlined,
                title: t('reading_plan'),
                onTap: () => open(const ReadingPlanScreen()),
              ),
              AppRow(
                icon: Icons.quiz_outlined,
                title: t('daily_quiz'),
                onTap: () => open(const DailyQuizScreen()),
              ),
              AppRow(
                icon: Icons.psychology_outlined,
                title: t('memorization'),
                onTap: () => open(const MemorizationScreen()),
              ),
              AppRow(
                icon: Icons.edit_note_outlined,
                title: t('prayer_journal'),
                onTap: () => open(const JournalScreen()),
              ),
              AppRow(
                icon: Icons.nights_stay_outlined,
                title: t('evening_examen'),
                onTap: () => open(const EveningExamenScreen()),
              ),
              AppRow(
                icon: Icons.flag_outlined,
                title: t('weekly_challenge'),
                onTap: () => open(const WeeklyChallengeScreen()),
              ),
            ]),
            const SizedBox(height: 24),
            SectionTitle(t('section_app')),
            AppRowGroup(rows: [
              AppRow(
                icon: Icons.settings_outlined,
                title: t('settings'),
                onTap: () => open(const SettingsScreen()),
              ),
              AppRow(
                icon: Icons.info_outline,
                title: t('nav_about'),
                onTap: () => open(const AboutScreen()),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
