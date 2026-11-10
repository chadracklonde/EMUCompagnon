import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/home/screens/home_screen.dart';
import '../features/bible/screens/books_screen.dart';
import '../features/hymns/screens/hymns_screen.dart';
import '../features/liturgy/screens/liturgy_screen.dart';
import '../features/more/screens/more_screen.dart';
import '../core/settings/app_settings.dart';
import '../core/l10n/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../shared/responsive/responsive.dart';

/// Adaptive navigation shell: a bottom bar on narrow (phone) windows, a
/// side rail on wide (desktop/web) windows — same 5 destinations, same
/// selection behaviour either way, decided purely by window width.
///
/// Dictionary, favourites and about used to be tabs of their own; they
/// now live under the fifth tab ("Plus") so the bar stays readable.
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
    MoreScreen(),
  ];

  // (outlined icon, filled icon when selected, label key)
  static const _destinations = [
    (Icons.home_outlined, Icons.home, 'nav_home'),
    (Icons.menu_book_outlined, Icons.menu_book, 'nav_bible'),
    (Icons.music_note_outlined, Icons.music_note, 'nav_hymns'),
    (Icons.calendar_month_outlined, Icons.calendar_month, 'nav_liturgy'),
    (Icons.more_horiz, Icons.more_horiz, 'nav_more'),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppSettings>().locale;
    String t(String key) => AppStrings.t(key, locale);

    final isWide = Responsive.isWide(context);

    if (!isWide) {
      return Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppPalette.of(context).border)),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final (icon, selectedIcon, key) in _destinations)
                NavigationDestination(
                  icon: Icon(icon),
                  selectedIcon: Icon(selectedIcon),
                  label: t(key),
                ),
            ],
          ),
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
              for (final (icon, selectedIcon, key) in _destinations)
                NavigationRailDestination(
                  icon: Icon(icon),
                  selectedIcon: Icon(selectedIcon),
                  label: Text(t(key)),
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
