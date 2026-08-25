import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// The visual design captured as an image when sharing a verse.
/// Kept visually simple and branded, sized for social sharing (portrait).
class VerseShareCard extends StatelessWidget {
  final String reference;
  final String text;

  const VerseShareCard({super.key, required this.reference, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 600,
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [UmcColors.burgundy, Color(0xFF4A1015)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.format_quote, color: Colors.white.withValues(alpha: 0.5), size: 40),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.4,
              fontWeight: FontWeight.w500,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 28),
          Container(width: 40, height: 3, color: const Color(0xFFD4A017)),
          const SizedBox(height: 16),
          Text(
            reference,
            style: const TextStyle(
              color: Color(0xFFD4A017),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'ÉMU Compagnon',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
