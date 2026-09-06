import 'package:flutter/material.dart';

/// Single source of truth for "is this a wide (desktop/web) layout or a
/// narrow (phone) one?" — based on the window's current width, not on
/// which platform is running. This means a resized desktop window or a
/// tablet in portrait mode correctly falls back to the narrow layout,
/// and a wide browser window gets the desktop layout even though it's
/// technically "web". Matches Material 3's "expanded" window size class
/// threshold.
class Responsive {
  static const double wideBreakpoint = 840;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideBreakpoint;
}
