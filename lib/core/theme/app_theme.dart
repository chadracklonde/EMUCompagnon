import 'package:flutter/material.dart';

/// Official brand colors of The United Methodist Church, per the UMC brand
/// guidelines (ResourceUMC.org / United Methodist Communications).
/// Source: https://www.resourceumc.org/en/content/brand-colors
class UmcColors {
  // Red palette
  static const redPrimary = Color(0xFFE4002B); // Pantone 185 — UMC Red (primary)
  static const redDark = Color(0xFFAF292E);    // Pantone 1805
  static const burgundy = Color(0xFF7A2426);   // Pantone 1815

  // Neutrals
  static const black = Color(0xFF000000);      // Primary black
  static const grayDark = Color(0xFF575A5D);   // Pantone 425
  static const grayLight = Color(0xFFB5B7B4);  // Pantone 421

  // Soft tint derived from redPrimary (85% white blend), used for
  // containers/highlights so accents stay visibly tied to the brand red
  // rather than introducing an unrelated hue.
  static const redTint = Color(0xFFFBD9DE);
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: UmcColors.burgundy,
      onPrimary: Colors.white,
      primaryContainer: UmcColors.redTint,
      onPrimaryContainer: UmcColors.burgundy,
      secondary: UmcColors.redPrimary,
      onSecondary: Colors.white,
      secondaryContainer: UmcColors.redTint,
      onSecondaryContainer: UmcColors.redDark,
      tertiary: UmcColors.redDark,
      onTertiary: Colors.white,
      surface: Colors.white,
      onSurface: UmcColors.black,
      surfaceContainerHighest: const Color(0xFFF1F0EF), // light neutral tint
      outline: UmcColors.grayDark,
      outlineVariant: UmcColors.grayLight,
      error: UmcColors.redPrimary,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: UmcColors.burgundy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: UmcColors.redTint,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? UmcColors.burgundy : UmcColors.grayDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? UmcColors.burgundy : UmcColors.grayDark,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: UmcColors.redPrimary,
        foregroundColor: Colors.white,
      ),
      fontFamily: 'Georgia',
    );
  }
}
