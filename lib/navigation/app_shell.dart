import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';
import '../core/services/widget_sync_service.dart';
import 'widget_router.dart';
import 'package:provider/provider.dart';
import '../features/home/screens/home_screen.dart';
import '../features/bible/screens/books_screen.dart';
import '../features/hymns/screens/hymns_screen.dart';
import '../features/liturgy/screens/liturgy_screen.dart';
import '../features/more/screens/more_screen.dart';
import '../features/reading_plan/services/reading_reminder.dart';
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

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;

  /// Tells the home tab it is being shown again, so it reloads its live
  /// cards (reading plan, quiz, favourite star).
  final _homeShown = ValueNotifier<int>(0);

  late final _screens = [
    HomeScreen(refresh: _homeShown),
    const BooksScreen(),
    const HymnsScreen(),
    const LiturgyScreen(),
    const MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // The reminder text names the next portion of the reading plan: bring
    // it up to date each time the app starts.
    ReadingReminder.sync();
    WidgetsBinding.instance.addObserver(this);
    _setUpShortcuts();
    WidgetSyncService.sync();
  }

  /// Leaving the app is when the home-screen widgets are brought up to date
  /// with what was just done (chapters read, quiz taken, favourites…).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) WidgetSyncService.sync();
  }

  /// Shortcuts offered by a long press on the app icon (Android and iOS).
  Future<void> _setUpShortcuts() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      const actions = QuickActions();
      await actions.initialize(_onShortcut);
      await actions.setShortcutItems(const [
        ShortcutItem(type: 'search', localizedTitle: 'Rechercher'),
        ShortcutItem(type: 'hymns', localizedTitle: 'Cantiques'),
        ShortcutItem(type: 'worship', localizedTitle: 'Culte du dimanche'),
      ]);
    } catch (_) {
      // Shortcuts are a convenience: the app works the same without them.
    }
  }

  void _onShortcut(String route) {
    if (!mounted) return;
    WidgetRouter.open(context, route, selectTab: _select);
  }

  void _select(int index) {
    setState(() => _index = index);
    if (index == 0) _homeShown.value++;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeShown.dispose();
    super.dispose();
  }

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
            onDestinationSelected: _select,
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
            onDestinationSelected: _select,
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
