import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/models/verse.dart';
import '../../bible/repository/bible_repository.dart';
import '../../bible/screens/books_screen.dart';
import '../../bible/screens/chapter_screen.dart';
import '../../hymns/screens/hymns_screen.dart';
import '../../dictionary/screens/dictionary_screen.dart';
import '../../favorites/screens/favorites_screen.dart';
import '../../about/screens/about_screen.dart';
import '../../liturgy/screens/liturgy_screen.dart';
import '../../reading_plan/screens/reading_plan_screen.dart';
import '../../search/screens/global_search_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/decorative_cross.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = BibleRepository();
  Verse? _verseOfTheDay;

  @override
  void initState() {
    super.initState();
    _repo.getVerseOfTheDay().then((v) {
      if (mounted) setState(() => _verseOfTheDay = v);
    });
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
    settings.setThemeMode(
      settings.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parchment = isDark ? const Color(0xFF241E1A) : UmcColors.parchment;
    final ink = isDark ? const Color(0xFFEDE3CC) : UmcColors.burgundy;

    return Scaffold(
      backgroundColor: parchment,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              locale: settings.locale,
              onLanguageTap: () => _pickLanguage(settings),
              onThemeTap: () => _toggleTheme(settings),
              onSettingsTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  _SearchBar(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _VerseOfTheDayCard(verse: _verseOfTheDay, ink: ink),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _TestamentButton(
                          label: 'Nouveau\nTestament',
                          cursive: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BooksScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _TestamentButton(
                          label: 'ANCIEN\nTESTAMENT',
                          cursive: false,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BooksScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _WideButton(
                    label: 'PLAN DE LECTURE',
                    icon: Icons.event_note_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReadingPlanScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _WideButton(
                    label: 'LITURGIE',
                    icon: Icons.menu_book_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LiturgyScreen()),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'ACCÈS RAPIDE',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: ink.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.6,
                    children: [
                      _SmallButton(
                        label: 'Cantiques',
                        icon: Icons.music_note_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HymnsScreen()),
                        ),
                      ),
                      _SmallButton(
                        label: 'Dictionnaire',
                        icon: Icons.auto_stories_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DictionaryScreen()),
                        ),
                      ),
                      _SmallButton(
                        label: 'Favoris',
                        icon: Icons.star_border,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                        ),
                      ),
                      _SmallButton(
                        label: 'À propos',
                        icon: Icons.info_outline,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String locale;
  final VoidCallback onLanguageTap;
  final VoidCallback onThemeTap;
  final VoidCallback onSettingsTap;

  const _TopBar({
    required this.locale,
    required this.onLanguageTap,
    required this.onThemeTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: UmcColors.burgundy,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: onLanguageTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.public, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    locale.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onThemeTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onSettingsTap,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.settings_outlined, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: UmcColors.gold.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: UmcColors.burgundy.withValues(alpha: 0.7)),
              const SizedBox(width: 10),
              Text(
                'RECHERCHE',
                style: GoogleFonts.playfairDisplay(
                  letterSpacing: 1.5,
                  fontSize: 13,
                  color: UmcColors.burgundy.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseOfTheDayCard extends StatelessWidget {
  final Verse? verse;
  final Color ink;
  const _VerseOfTheDayCard({required this.verse, required this.ink});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: verse == null
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChapterScreen(
                  book: verse!.book,
                  chapter: verse!.chapter,
                  highlightVerse: verse!.verse,
                ),
              )),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: UmcColors.gold, width: 1.4),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: UmcColors.gold.withValues(alpha: 0.6), width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(
            children: [
              Text(
                'Verset du Jour',
                textAlign: TextAlign.center,
                style: GoogleFonts.greatVibes(
                  fontSize: 34,
                  color: ink,
                ),
              ),
              if (verse != null) ...[
                const SizedBox(height: 14),
                Text(
                  verse!.text,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, height: 1.5, color: ink.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 8),
                Text(
                  verse!.reference,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: UmcColors.gold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TestamentButton extends StatelessWidget {
  final String label;
  final bool cursive;
  final VoidCallback onTap;
  const _TestamentButton({required this.label, required this.cursive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: UmcColors.burgundy,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 130,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: UmcColors.gold, width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecorativeCross(size: 30, color: UmcColors.gold),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: cursive
                    ? GoogleFonts.greatVibes(fontSize: 24, color: Colors.white, height: 1.1)
                    : GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Colors.white,
                        height: 1.3,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _WideButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: UmcColors.burgundy,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: UmcColors.gold, width: 1.4),
          ),
          child: Row(
            children: [
              Icon(icon, color: UmcColors.gold, size: 24),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 24), // balances the leading icon width
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SmallButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: UmcColors.gold.withValues(alpha: 0.7)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: UmcColors.burgundy, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: UmcColors.burgundy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
