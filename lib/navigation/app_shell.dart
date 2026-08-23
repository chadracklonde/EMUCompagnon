import 'package:flutter/material.dart';
import '../features/bible/screens/books_screen.dart';
import '../features/hymns/screens/hymns_screen.dart';
import '../features/dictionary/screens/dictionary_screen.dart';
import '../features/favorites/screens/favorites_screen.dart';
import '../features/about/screens/about_screen.dart';

/// Bottom-navigation shell hosting the active modules.
/// A "Liturgie" tab will be added once that content is ready.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    BooksScreen(),
    HymnsScreen(),
    DictionaryScreen(),
    FavoritesScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Bible'),
          NavigationDestination(icon: Icon(Icons.music_note), label: 'Cantiques'),
          NavigationDestination(icon: Icon(Icons.auto_stories), label: 'Dictionnaire'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Favoris'),
          NavigationDestination(icon: Icon(Icons.info_outline), label: 'À propos'),
        ],
      ),
    );
  }
}
