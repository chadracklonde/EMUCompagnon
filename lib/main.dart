import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_shell.dart';

void main() {
  runApp(const EmuCompagnonApp());
}

class EmuCompagnonApp extends StatelessWidget {
  const EmuCompagnonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMU Compagnon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
