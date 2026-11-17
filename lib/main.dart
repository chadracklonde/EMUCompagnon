import 'features/audio_pack/screens/audio_pack_offer_screen.dart';
import 'features/audio_pack/hymn_audio_pack.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_shell.dart';
import 'features/onboarding/services/onboarding_service.dart';
import 'features/onboarding/screens/language_welcome_screen.dart';

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
  Widget? _start;

  @override
  void initState() {
    super.initState();
    // Ce qui est déjà téléchargé du pack d'écoute hors ligne (sans attendre).
    HymnAudioPack.instance.ensureLoaded().catchError((_) {});
    _decide();
  }

  /// Nouvelle installation : le choix de la langue, puis le tutoriel dans la
  /// langue choisie, puis (une fois) la proposition de télécharger les
  /// enregistrements, puis l'application. Installation existante : la
  /// proposition une seule fois, puis l'application.
  Future<void> _decide() async {
    final seen = await OnboardingService.hasSeenOnboarding();
    Widget start;
    if (!seen) {
      start = const LanguageWelcomeScreen();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final locale = prefs.getString('settings.locale') ?? 'fr';
      start = await AudioPackOffer.shouldShow(locale)
          ? AudioPackOfferScreen(next: (_) => const AppShell())
          : const AppShell();
    }
    if (mounted) setState(() => _start = start);
  }

  @override
  Widget build(BuildContext context) {
    final start = _start;
    if (start == null) {
      // Brief splash while the preference loads — effectively instant on
      // device, avoids a flash of the wrong screen.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return start;
  }
}
