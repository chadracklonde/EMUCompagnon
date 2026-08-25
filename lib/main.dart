import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_shell.dart';
import 'features/onboarding/services/onboarding_service.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

void main() {
  runApp(const EmuCompagnonApp());
}

class EmuCompagnonApp extends StatelessWidget {
  const EmuCompagnonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppSettings>(
      create: (_) => AppSettings()..load(),
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'ÉMU Compagnon',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(fontFamily: settings.resolvedFontFamily),
            darkTheme: AppTheme.dark(fontFamily: settings.resolvedFontFamily),
            themeMode: settings.themeMode,
            // Applies the user's text-size preference app-wide, on top of
            // each widget's own font sizes.
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settings.textScale),
                ),
                child: child!,
              );
            },
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}

/// Decides, on cold start, whether to show the first-launch onboarding
/// tour or go straight to the app. Checked once via SharedPreferences.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    OnboardingService.hasSeenOnboarding().then((seen) {
      if (mounted) setState(() => _hasSeenOnboarding = seen);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenOnboarding == null) {
      // Brief splash while the preference loads — effectively instant on
      // device, avoids a flash of the wrong screen.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _hasSeenOnboarding! ? const AppShell() : const OnboardingScreen();
  }
}
