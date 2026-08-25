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

/// Bottom-navigation shell hosting the active modules.
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

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppSettings>().locale;
    String t(String key) => AppStrings.t(key, locale);

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: const Icon(Icons.menu_book), label: t('nav_bible')),
          NavigationDestination(icon: const Icon(Icons.music_note), label: t('nav_hymns')),
          NavigationDestination(icon: const Icon(Icons.calendar_month), label: t('nav_liturgy')),
          NavigationDestination(icon: const Icon(Icons.auto_stories), label: t('nav_dictionary')),
          NavigationDestination(icon: const Icon(Icons.star), label: t('nav_favorites')),
          NavigationDestination(icon: const Icon(Icons.info_outline), label: t('nav_about')),
        ],
      ),
    );
  }
}
