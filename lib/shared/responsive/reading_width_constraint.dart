import 'package:flutter/material.dart';
import 'responsive.dart';

/// Wraps a screen's scrollable body so that, on wide (desktop/web)
/// windows, the text column stays a comfortable reading width instead of
/// stretching edge-to-edge across a large monitor. On narrow (phone)
/// windows this is a no-op — full width, exactly as before.
class ReadingWidthConstraint extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ReadingWidthConstraint({
    super.key,
    required this.child,
    this.maxWidth = 760,
  });

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isWide(context)) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
