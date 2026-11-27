import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

/// Une capture d'écran de l'aide et les zones qu'on peut toucher dessus.
///
/// L'image est `assets/help/<langue>/<id>.webp`. Les positions des zones,
/// relevées au moment de la capture, sont dans `assets/help/shots.json`
/// (fractions de la largeur et de la hauteur de l'image).
class HelpShotInfo {
  final double width;
  final double height;
  final Map<String, List<double>> rects;
  const HelpShotInfo(this.width, this.height, this.rects);
  double get ratio => width / height;
}

class HelpShots {
  static Map<String, dynamic>? _manifest;

  /// Pour les tests : remplace la lecture des ressources.
  @visibleForTesting
  static Future<ByteData> Function(String key)? loader;

  @visibleForTesting
  static void resetForTests() => _manifest = null;

  static Future<ByteData> _load(String key) => (loader ?? rootBundle.load)(key);

  static Future<Map<String, dynamic>> _read() async {
    final cached = _manifest;
    if (cached != null) return cached;
    try {
      final data = await _load('assets/help/shots.json');
      final text = utf8.decode(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      return _manifest = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return _manifest = <String, dynamic>{};
    }
  }

  /// Les informations d'une capture, ou null quand elle n'existe pas dans
  /// cette langue (l'aide s'affiche alors sans l'image).
  static Future<HelpShotInfo?> info(String lang, String id) async {
    final m = await _read();
    final e = (m[lang] as Map<String, dynamic>?)?[id] as Map<String, dynamic>?;
    if (e == null) return null;
    final rects = <String, List<double>>{
      for (final r in ((e['rects'] as Map<String, dynamic>?) ?? {}).entries)
        r.key: [for (final v in r.value as List) (v as num).toDouble()],
    };
    return HelpShotInfo((e['w'] as num).toDouble(), (e['h'] as num).toDouble(), rects);
  }

  static Future<Uint8List?> image(String lang, String id) async {
    try {
      final d = await _load('assets/help/$lang/$id.webp');
      return d.buffer.asUint8List(d.offsetInBytes, d.lengthInBytes);
    } catch (_) {
      return null;
    }
  }
}
