import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/home/screens/home_screen.dart';
import '../features/bible/screens/books_screen.dart';
import '../features/hymns/screens/hymns_screen.dart';
import '../features/dictionary/screens/dictionary_screen.dart';
import '../features/liturgy/screens/liturgy_screen.dart';
import '../features/favorites/screens/favorites_screen.dart';
import '../features/about/screens/about_screen.dart';
import '../core/settings/app_settings.dart';
import '../core/l10n/app_strings.dart';
import '../shared/responsive/responsive.dart';

/// Adaptive navigation shell: a bottom bar on narrow (phone) windows, a
/// side rail on wide (desktop/web) windows — same 7 destinations, same
/// selection behaviour either way, decided purely by window width.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    BooksScreen(),
    HymnsScreen(),
    LiturgyScreen(),
    DictionaryScreen(),
    FavoritesScreen(),
    AboutScreen(),
  ];

  static const _icons = [
    Icons.home,
    Icons.menu_book,
    Icons.music_note,
    Icons.calendar_month,
    Icons.auto_stories,
    Icons.star,
    Icons.info_outline,
  ];

  static const _labelKeys = [
    null, // "Accueil" has no existing AppStrings key; handled inline below
    'nav_bible',
    'nav_hymns',
    'nav_liturgy',
    'nav_dictionary',
    'nav_favorites',
    'nav_about',
  ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppSettings>().locale;
    String t(String key) => AppStrings.t(key, locale);
    final labels = [
      'Accueil',
      for (final key in _labelKeys.skip(1)) t(key!),
    ];

    final isWide = Responsive.isWide(context);

    if (!isWide) {
      return Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            for (var i = 0; i < _icons.length; i++)
              NavigationDestination(icon: Icon(_icons[i]), label: labels[i]),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (var i = 0; i < _icons.length; i++)
                NavigationRailDestination(
                  icon: Icon(_icons[i]),
                  label: Text(labels[i]),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(index: _index, children: _screens),
          ),
        ],
      ),
    );
  }
}
