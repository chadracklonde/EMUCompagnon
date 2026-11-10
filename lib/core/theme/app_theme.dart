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

  // Decorative gold, used for the app icon flame, shared verse cards, and
  // liturgical color swatches — not an official UMC brand color, but the
  // app's own established accent for ornamental/classic-style elements.
  static const gold = Color(0xFFD4A017);

  // Warm parchment/cream tone for the "elegant classic" home screen
  // background, evoking an old missal/hymnal page.
  static const parchment = Color(0xFFF7F1E1);
}

/// Neutral surfaces of the "clair et aéré" look (cards on a soft
/// background), resolved for the current brightness. Brand accents still
/// come from the [ColorScheme] (`primary`, `onSurface`…).
class AppPalette {
  final Color background;
  final Color card;
  final Color border;
  final Color field;
  final Color muted;
  final Color accent;
  final Color accentSoft;

  const AppPalette._({
    required this.background,
    required this.card,
    required this.border,
    required this.field,
    required this.muted,
    required this.accent,
    required this.accentSoft,
  });

  /// Filled "hero" card (verse of the day): same burgundy in both modes.
  static const hero = UmcColors.burgundy;
  static const onHero = Colors.white;
  static const onHeroMuted = Color(0xFFF3C9CC);

  static const _light = AppPalette._(
    background: Color(0xFFFAF9F7),
    card: Colors.white,
    border: Color(0xFFE8E4E0),
    field: Color(0xFFF0EEEB),
    muted: Color(0xFF6B6466),
    accent: UmcColors.burgundy,
    accentSoft: Color(0xFFF7E9EA),
  );

  static const _dark = AppPalette._(
    background: Color(0xFF161213),
    card: Color(0xFF221D1E),
    border: Color(0xFF362F31),
    field: Color(0xFF2A2425),
    muted: Color(0xFFB9B1B3),
    accent: Color(0xFFE08A8F),
    accentSoft: Color(0xFF3A1F22),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

class AppTheme {
  static ThemeData light({String? fontFamily}) {
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
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
      fontFamily: fontFamily,
    );
  }

  static ThemeData dark({String? fontFamily}) {
    // Dark surfaces with the same UMC brand accents, adjusted for contrast
    // and to avoid pure-black eye strain during long reading sessions.
    const surfaceDark = Color(0xFF161213);
    const surfaceContainerDark = Color(0xFF221D1E);
    const redAccent = Color(0xFFFF5C6C); // lightened UMC red for dark bg contrast

    final colorScheme = ColorScheme.dark(
      primary: const Color(0xFFE08A8F), // lightened burgundy for legibility
      onPrimary: const Color(0xFF3A0E12),
      primaryContainer: const Color(0xFF4A1A1F),
      onPrimaryContainer: const Color(0xFFF5D6D8),
      secondary: redAccent,
      onSecondary: const Color(0xFF3A0006),
      secondaryContainer: const Color(0xFF4A1015),
      onSecondaryContainer: const Color(0xFFFFD9DC),
      tertiary: const Color(0xFFD98A8C),
      onTertiary: const Color(0xFF3A0006),
      surface: surfaceDark,
      onSurface: const Color(0xFFEAE1E2),
      surfaceContainerHighest: surfaceContainerDark,
      outline: UmcColors.grayLight,
      outlineVariant: const Color(0xFF4A4547),
      error: redAccent,
      onError: const Color(0xFF3A0006),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF3A1418),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainerDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: const Color(0xFF4A1A1F),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? const Color(0xFFE08A8F) : UmcColors.grayLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? const Color(0xFFE08A8F) : UmcColors.grayLight,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: redAccent,
        foregroundColor: const Color(0xFF3A0006),
      ),
      fontFamily: fontFamily,
    );
  }
}
