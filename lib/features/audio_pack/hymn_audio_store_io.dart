import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'hymn_audio_store.dart';

/// Les enregistrements dans le dossier privé de l'application
/// (`<support>/hymn_audio/`). Le dossier est donné en paramètre pour les tests.
class IoHymnAudioStore implements HymnAudioStore {
  final Future<Directory> Function() _root;
  IoHymnAudioStore([Future<Directory> Function()? root])
      : _root = root ?? _defaultRoot;

  static Future<Directory> _defaultRoot() async =>
      Directory(p.join((await getApplicationSupportDirectory()).path, 'hymn_audio'));

  @override
  bool get supported => true;

  @override
  Future<String?> pathIfValid(String name, int size) async {
    try {
      final file = File(p.join((await _root()).path, name));
      if (await file.exists() && await file.length() == size) return file.path;
    } catch (_) {}
    return null;
  }

  @override
  Future<void> write(String name, List<int> bytes) async {
    final dir = await _root();
    await dir.create(recursive: true);
    final temp = File(p.join(dir.path, '$name.part'));
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(p.join(dir.path, name));
  }

  @override
  Future<void> clear() async {
    final dir = await _root();
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

HymnAudioStore createHymnAudioStore() => IoHymnAudioStore();
