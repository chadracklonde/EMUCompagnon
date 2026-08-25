import 'package:flutter/material.dart';
import 'bookmark.dart'; // reuses BookmarkType (verse/hymn/dictionary)

/// A small, fixed palette so highlight colors stay consistent and
/// meaningful (rather than an arbitrary color picker).
class HighlightColors {
  static const Map<String, Color> palette = {
    'jaune': Color(0xFFFFE066),
    'vert': Color(0xFFA8E6A1),
    'bleu': Color(0xFFA0C4FF),
    'rose': Color(0xFFFFB3C6),
    'orange': Color(0xFFFFC385),
  };

  static Color colorFor(String hex) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    if (value == null) return palette['jaune']!;
    return Color(0xFF000000 | value);
  }

  static String hexFor(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

class VerseHighlight {
  final int id;
  final BookmarkType type;
  final int refId;
  final String colorHex;
  final DateTime createdAt;

  VerseHighlight({
    required this.id,
    required this.type,
    required this.refId,
    required this.colorHex,
    required this.createdAt,
  });

  factory VerseHighlight.fromMap(Map<String, dynamic> map) => VerseHighlight(
        id: map['id'] as int,
        type: BookmarkType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => BookmarkType.verse,
        ),
        refId: map['ref_id'] as int,
        colorHex: map['color_hex'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
