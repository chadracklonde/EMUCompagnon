import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/bookmark.dart';
import '../../../core/models/verse.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/services/image_share_service.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../bible/repository/bible_repository.dart';
import '../../bible/screens/books_screen.dart';
import '../../bible/screens/chapter_screen.dart';
import '../../daily_quiz/screens/daily_quiz_screen.dart';
import '../../daily_quiz/services/daily_quiz_service.dart';
import '../../evening_examen/screens/evening_examen_screen.dart';
import '../../favorites/repository/bookmark_repository.dart';
import '../../hymns/screens/hymns_screen.dart';
import '../../journal/screens/journal_screen.dart';
import '../../liturgy/models/liturgical_period.dart';
import '../../liturgy/screens/liturgy_screen.dart';
import '../../liturgy/services/liturgical_calendar_service.dart';
import '../../memorization/screens/memorization_screen.dart';
import '../../reading_plan/screens/reading_plan_screen.dart';
import '../../reading_plan/services/reading_plan_service.dart';
import '../../search/screens/global_search_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../weekly_challenge/screens/weekly_challenge_screen.dart';
import '../../church_texts/data/church_texts_data.dart';
import '../../church_texts/models/church_text.dart';
import '../../church_texts/screens/church_text_screen.dart';
import '../../church_texts/screens/church_texts_screen.dart';
import '../../church_texts/services/church_text_prefs.dart';
import '../../worship/screens/worship_screen.dart';
import '../../backup/screens/backup_screen.dart';
import '../../backup/services/backup_service.dart';
import '../../../shared/bible_book_names.dart';

/// Home tab, "clair et aéré" look: greeting and date, search, the verse of
/// the day as the one filled burgundy card, then plain bordered tiles.
/// "Aujourd'hui" shows live state (reading-plan progress, today's quiz)
/// instead of bare shortcuts.
class HomeScreen extends StatefulWidget {
  /// Fires when the home tab is shown again. The tab stays alive behind
  /// the others, so without it "Aujourd'hui" would keep showing the state
  /// from before the user read a chapter or changed their plan elsewhere.
  final Listenable? refresh;
  const HomeScreen({super.key, this.refresh});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = BibleRepository();
  final _bookmarks = BookmarkRepository();

  Verse? _verseOfTheDay;
  bool _verseFailed = false;
  bool _verseIsFavorite = false;
  StreakInfo? _streak;
  LiturgicalPeriodInstance? _season;

  ReadingPlan? _plan;
  DailyQuizResult? _quizResult;

  /// Prayers and texts pinned from their reading page.
  List<ChurchText> _pinnedTexts = [];

  /// Personal data exists and has not been exported for a month.
  bool _backupDue = false;

  @override
  void initState() {
    super.initState();
    try {
      _season = LiturgicalCalendarService.currentSeason().$1;
    } catch (_) {
      // The season is a nicety on this screen; the tile falls back to a
      // generic subtitle.
    }
    _loadVerseOfDay();
    _loadToday();
    widget.refresh?.addListener(_onShownAgain);
    StreakService.recordVisitToday().then((s) {
      if (mounted) setState(() => _streak = s);
    });
  }

  String? _shownVersion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Le verset du jour suit la langue : on le recharge quand elle change.
    final v = Provider.of<AppSettings>(context).bibleVersion;
    if (_shownVersion != null && _shownVersion != v) _loadVerseOfDay();
    _shownVersion = v;
  }

  void _onShownAgain() {
    _loadToday();
    _refreshFavorite();
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_onShownAgain);
    super.dispose();
  }

  /// Loads the verse of the day, retrying a couple of times. A failure here
  /// used to be swallowed silently (an un-awaited `.then` with no error
  /// handler), leaving the card empty for the whole session.
  Future<void> _loadVerseOfDay() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final v = await _repo.getVerseOfTheDay();
        if (!mounted) return;
        setState(() {
          _verseOfTheDay = v;
          _verseFailed = v == null;
        });
        _refreshFavorite();
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
      }
    }
    if (mounted) setState(() => _verseFailed = true);
  }

  Future<void> _refreshFavorite() async {
    final verse = _verseOfTheDay;
    if (verse == null) return;
    try {
      final fav = await _bookmarks.isBookmarked(BookmarkType.verse, verse.id);
      if (mounted) setState(() => _verseIsFavorite = fav);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final verse = _verseOfTheDay;
    if (verse == null) return;
    final fav = await _bookmarks.toggle(BookmarkType.verse, verse.id);
    if (mounted) setState(() => _verseIsFavorite = fav);
  }

  /// Reading-plan progress and today's quiz result. Called again each time
  /// the user comes back from a pushed screen, since either may have changed.
  Future<void> _loadToday() async {
    try {
      final quiz = await DailyQuizService.getTodayResult();
      if (mounted) setState(() => _quizResult = quiz);
    } catch (_) {}
    try {
      final plan = await ReadingPlanService.getPlan();
      if (mounted) setState(() => _plan = plan);
    } catch (_) {}
    final backupDue = await BackupService().shouldRemind();
    if (mounted) setState(() => _backupDue = backupDue);
    final pinned = await ChurchTextPrefs.pinned();
    if (mounted) {
      setState(() => _pinnedTexts = [
            for (final id in pinned)
              if (ChurchTextsData.byId(id) != null) ChurchTextsData.byId(id)!,
          ]);
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    _loadToday();
    _refreshFavorite();
  }

  Future<void> _pickLanguage(AppSettings settings) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check, color: Colors.transparent),
              title: const Text('Français'),
              trailing: settings.locale == 'fr' ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, 'fr'),
            ),
            ListTile(
              leading: const Icon(Icons.check, color: Colors.transparent),
              title: const Text('Kiswahili'),
              trailing: settings.locale == 'sw' ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, 'sw'),
            ),
          ],
        ),
      ),
    );
    if (chosen != null) settings.setLocale(chosen);
  }

  void _toggleTheme(AppSettings settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    settings.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final locale = settings.locale;
    String t(String key) => AppStrings.t(key, locale);
    String tf(String key, Map<String, Object> values) =>
        AppStrings.tf(key, locale, values);

    final palette = AppPalette.of(context);
    final verse = _verseOfTheDay;
    final season = _season;

    final plan = _plan;
    final planNext = plan?.nextDay;
    final String? planSubtitle;
    if (plan == null) {
      planSubtitle = null;
    } else if (planNext == null) {
      planSubtitle = t('reading_plan_done');
    } else {
      planSubtitle = '${tf('reading_plan_next', {'ref': planNext.label})}'
          '\n${tf('reading_plan_progress', {
                'done': plan.readChapters,
                'total': plan.totalChapters,
              })}';
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: ReadingWidthConstraint(
          maxWidth: 640,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _Header(
                greeting: t(DateTime.now().hour < 18 ? 'greeting_day' : 'greeting_evening'),
                date: AppStrings.longDate(DateTime.now(), locale),
                streakLabel: _streak != null && _streak!.current > 1
                    ? tf('streak_days', {'n': _streak!.current})
                    : null,
                languageTooltip: t('language'),
                themeTooltip: t('theme_toggle'),
                settingsTooltip: t('settings'),
                onLanguageTap: () => _pickLanguage(settings),
                onThemeTap: () => _toggleTheme(settings),
                onSettingsTap: () => _open(const SettingsScreen()),
              ),
              const SizedBox(height: 14),
              _SearchField(
                label: t('search_everywhere'),
                onTap: () => _open(const GlobalSearchScreen()),
              ),
              const SizedBox(height: 16),
              _VerseOfTheDayCard(
                title: t('verse_of_the_day'),
                verse: verse,
                failedMessage: _verseFailed ? t('verse_unavailable') : null,
                isFavorite: _verseIsFavorite,
                favoriteTooltip: t(_verseIsFavorite ? 'favorite_remove' : 'favorite_add'),
                shareTooltip: t('share'),
                onTap: verse == null
                    ? null
                    : () => _open(ChapterScreen(
                          book: verse.book,
                          chapter: verse.chapter,
                          highlightVerse: verse.verse,
                        )),
                onFavorite: _toggleFavorite,
                onShare: verse == null
                    ? null
                    : () => ImageShareService.shareVerse(
                          context,
                          reference: context.bookReference(verse.reference),
                          text: verse.text,
                        ),
              ),
              if (_backupDue) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pensez à sauvegarder vos données',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'Vos notes, favoris et surlignages ne sont enregistrés que '
                            'sur ce téléphone. Exportez-les pour ne pas les perdre.',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: AppPalette.of(context).muted,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                setState(() => _backupDue = false);
                                await BackupService.snoozeReminder();
                              },
                              child: const Text('Plus tard'),
                            ),
                            TextButton(
                              onPressed: () => _open(const BackupScreen()),
                              child: const Text('Sauvegarder'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SectionTitle(t('section_read_sing')),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: AppTile(
                        icon: Icons.menu_book_outlined,
                        title: t('old_testament'),
                        subtitle: tf('books_count', {'n': 39}),
                        onTap: () => _open(
                          const BooksScreen(filter: TestamentFilter.oldTestament),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTile(
                        icon: Icons.menu_book_outlined,
                        title: t('new_testament'),
                        subtitle: tf('books_count', {'n': 27}),
                        onTap: () => _open(
                          const BooksScreen(filter: TestamentFilter.newTestament),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: AppTile(
                        icon: Icons.music_note_outlined,
                        title: 'Chants de Victoire',
                        subtitle: t('hymnal_subtitle'),
                        onTap: () => _open(const HymnsScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTile(
                        icon: Icons.calendar_month_outlined,
                        title: t('nav_liturgy'),
                        subtitle: season?.period.name ?? t('liturgy_subtitle'),
                        subtitleDot: season == null ? null : Color(season.period.colorHex),
                        onTap: () => _open(const LiturgyScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: AppRow(
                  icon: Icons.church_outlined,
                  title: t('worship_sunday'),
                  subtitle: t('worship_sunday_subtitle'),
                  onTap: () => _open(const WorshipScreen()),
                ),
              ),
              const SizedBox(height: 24),
              SectionTitle(t('prayers_texts')),
              AppRowGroup(rows: [
                for (final text in _pinnedTexts)
                  AppRow(
                    icon: churchTextIcon(text.icon),
                    title: text.title,
                    subtitle: text.subtitle,
                    onTap: () => _open(ChurchTextScreen(text: text)),
                  ),
                AppRow(
                  icon: Icons.auto_stories_outlined,
                  title: _pinnedTexts.isEmpty ? t('prayers_texts') : t('prayers_texts_all'),
                  subtitle: _pinnedTexts.isEmpty
                      ? 'Notre Père, Credo social, Articles de religion…'
                      : null,
                  onTap: () => _open(const ChurchTextsScreen()),
                ),
              ]),
              const SizedBox(height: 24),
              SectionTitle(t('section_today')),
              AppCard(
                child: AppRow(
                  icon: Icons.event_note_outlined,
                  title: t('reading_plan'),
                  subtitle: planSubtitle,
                  progress: plan?.progress,
                  onTap: () => _open(const ReadingPlanScreen()),
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: AppRow(
                  icon: Icons.quiz_outlined,
                  title: t('daily_quiz'),
                  subtitle: _quizResult == null
                      ? tf('daily_quiz_questions', {'n': DailyQuizService.questionsPerDay})
                      : tf('daily_quiz_done', {
                          'score': _quizResult!.score,
                          'total': _quizResult!.total,
                        }),
                  onTap: () => _open(const DailyQuizScreen()),
                ),
              ),
              const SizedBox(height: 24),
              SectionTitle(t('section_spiritual_life')),
              AppRowGroup(rows: [
                AppRow(
                  icon: Icons.psychology_outlined,
                  title: t('memorization'),
                  onTap: () => _open(const MemorizationScreen()),
                ),
                AppRow(
                  icon: Icons.edit_note_outlined,
                  title: t('prayer_journal'),
                  onTap: () => _open(const JournalScreen()),
                ),
                AppRow(
                  icon: Icons.nights_stay_outlined,
                  title: t('evening_examen'),
                  onTap: () => _open(const EveningExamenScreen()),
                ),
                AppRow(
                  icon: Icons.flag_outlined,
                  title: t('weekly_challenge'),
                  onTap: () => _open(const WeeklyChallengeScreen()),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final String date;
  final String? streakLabel;
  final String languageTooltip;
  final String themeTooltip;
  final String settingsTooltip;
  final VoidCallback onLanguageTap;
  final VoidCallback onThemeTap;
  final VoidCallback onSettingsTap;

  const _Header({
    required this.greeting,
    required this.date,
    required this.streakLabel,
    required this.languageTooltip,
    required this.themeTooltip,
    required this.settingsTooltip,
    required this.onLanguageTap,
    required this.onThemeTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(date, style: TextStyle(fontSize: 13, color: palette.muted)),
              if (streakLabel != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_outlined,
                          size: 16, color: palette.accent),
                      const SizedBox(width: 5),
                      Text(
                        streakLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: languageTooltip,
          onPressed: onLanguageTap,
          color: scheme.onSurface,
          icon: const Icon(Icons.language),
        ),
        IconButton(
          tooltip: themeTooltip,
          onPressed: onThemeTap,
          color: scheme.onSurface,
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        ),
        IconButton(
          tooltip: settingsTooltip,
          onPressed: onSettingsTap,
          color: scheme.onSurface,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

/// Looks like a text field but only opens the global search screen.
class _SearchField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SearchField({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      child: Material(
        color: palette.field,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.search, color: palette.muted, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, color: palette.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerseOfTheDayCard extends StatelessWidget {
  final String title;
  final Verse? verse;
  final String? failedMessage;
  final bool isFavorite;
  final String favoriteTooltip;
  final String shareTooltip;
  final VoidCallback? onTap;
  final VoidCallback onFavorite;
  final VoidCallback? onShare;

  const _VerseOfTheDayCard({
    required this.title,
    required this.verse,
    required this.failedMessage,
    required this.isFavorite,
    required this.favoriteTooltip,
    required this.shareTooltip,
    required this.onTap,
    required this.onFavorite,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final verse = this.verse;
    return Material(
      color: AppPalette.hero,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: AppPalette.onHeroMuted,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: verse != null
                    ? Text(
                        verse.text,
                        maxLines: 7,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 20,
                          height: 1.4,
                          color: AppPalette.onHero,
                        ),
                      )
                    : failedMessage != null
                        ? Text(
                            failedMessage!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: AppPalette.onHeroMuted,
                            ),
                          )
                        : const _VersePlaceholder(),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.bookReference(verse?.reference ?? ''),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.onHero,
                      ),
                    ),
                  ),
                  if (verse != null) ...[
                    IconButton(
                      tooltip: favoriteTooltip,
                      onPressed: onFavorite,
                      color: AppPalette.onHero,
                      icon: Icon(isFavorite ? Icons.star : Icons.star_outline),
                    ),
                    IconButton(
                      tooltip: shareTooltip,
                      onPressed: onShare,
                      color: AppPalette.onHero,
                      icon: const Icon(Icons.ios_share),
                    ),
                  ] else
                    const SizedBox(height: 48),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two soft bars standing in for the verse while it loads, so the card
/// keeps its height instead of jumping when the text arrives.
class _VersePlaceholder extends StatelessWidget {
  const _VersePlaceholder();

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor) => FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [bar(1), const SizedBox(height: 12), bar(0.7)],
    );
  }
}
