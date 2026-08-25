import 'package:flutter/material.dart';

/// Cream/parchment + navy + gold palette used specifically for the home
/// screen's classic, elegant look — intentionally distinct from the
/// official UMC brand colors (UmcColors, in core/theme/app_theme.dart)
/// used throughout the rest of the app. If this look is ever meant to
/// replace the app-wide theme, that's a separate, bigger decision.
class HomeColors {
  static const cream = Color(0xFFF7F0DE);
  static const creamDark = Color(0xFF2A2620); // dark-mode "parchment"
  static const navy = Color(0xFF1B3350);
  static const navyLight = Color(0xFF24446B);
  static const gold = Color(0xFFC9A24B);
  static const goldSoft = Color(0xFFDCC079);
}
