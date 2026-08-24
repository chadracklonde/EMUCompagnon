import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_shell.dart';

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
            title: 'EMU Compagnon',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
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
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
