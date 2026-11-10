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

    return _build(
      colorScheme: colorScheme,
      palette: AppPalette._light,
      fontFamily: fontFamily,
      navSelected: UmcColors.burgundy,
      navUnselected: UmcColors.grayDark,
      navIndicator: UmcColors.redTint,
      fabBackground: UmcColors.redPrimary,
      fabForeground: Colors.white,
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

    return _build(
      colorScheme: colorScheme,
      palette: AppPalette._dark,
      fontFamily: fontFamily,
      navSelected: const Color(0xFFE08A8F),
      navUnselected: UmcColors.grayLight,
      navIndicator: const Color(0xFF4A1A1F),
      fabBackground: redAccent,
      fabForeground: const Color(0xFF3A0006),
    );
  }

  /// Everything both brightnesses share: the "clair et aéré" look — soft
  /// background, flat app bars in the page colour, bordered cards, filled
  /// rounded fields. Only colours differ between light and dark.
  static ThemeData _build({
    required ColorScheme colorScheme,
    required AppPalette palette,
    required String? fontFamily,
    required Color navSelected,
    required Color navUnselected,
    required Color navIndicator,
    required Color fabBackground,
    required Color fabForeground,
  }) {
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      fontFamily: fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(iconColor: palette.accent),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.field,
        hintStyle: TextStyle(color: palette.muted),
        prefixIconColor: palette.muted,
        suffixIconColor: palette.muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: buttonShape, minimumSize: const Size(48, 48)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: buttonShape,
          elevation: 0,
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: buttonShape,
          side: BorderSide(color: palette.border),
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.card,
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: navIndicator,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? navSelected : navUnselected,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? navSelected : navUnselected);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: palette.accent,
        unselectedLabelColor: palette.muted,
        indicatorColor: palette.accent,
        dividerColor: palette.border,
        labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: palette.card,
        indicatorColor: navIndicator,
        selectedIconTheme: IconThemeData(color: navSelected),
        unselectedIconTheme: IconThemeData(color: navUnselected),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: fabBackground,
        foregroundColor: fabForeground,
        elevation: 2,
      ),
    );
  }
}
