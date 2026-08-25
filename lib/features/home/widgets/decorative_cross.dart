import 'package:flutter/material.dart';

/// A simple Latin cross, drawn with two rectangles since Material Icons
/// has no cross glyph. Kept intentionally plain/geometric to match the
/// classic, ornamental style of the home screen.
class DecorativeCross extends StatelessWidget {
  final double size;
  final Color color;
  const DecorativeCross({super.key, this.size = 32, required this.color});

  @override
  Widget build(BuildContext context) {
    final barThickness = size * 0.16;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vertical bar
          Container(
            width: barThickness,
            height: size,
            color: color,
          ),
          // Horizontal bar, positioned slightly above center like a
          // traditional Latin cross.
          Positioned(
            top: size * 0.22,
            child: Container(
              width: size * 0.68,
              height: barThickness,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
