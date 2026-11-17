import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../../shared/widgets/hymn_audio_player.dart' show HymnAudio;
import 'hymn_audio_store.dart';

/// Un enregistrement du pack : son nom (`6.m4a`) et sa taille exacte en octets.
class AudioFile {
  final String name;
  final int size;
  const AudioFile(this.name, this.size);

  /// Chemin relatif tel qu'il est gardé dans la base (`hymn_audio/6.m4a`).
  String get audioUrl => 'hymn_audio/$name';
}

enum AudioPackState { idle, downloading, error }

/// Le pack d'écoute hors ligne : télécharge les enregistrements des cantiques
/// sur l'appareil pour les écouter sans connexion.
///
/// - Un fichier à la fois, vérifié (taille exacte) avant d'être gardé ; un
///   fichier déjà là n'est jamais retéléchargé, donc une coupure se rattrape en
///   relançant : « Réessayer » reprend où l'on s'était arrêté.
/// - Le téléchargement continue pendant qu'on utilise l'application (c'est un
///   service unique, [instance]) ; il s'arrête si le système ferme l'application.
class HymnAudioPack extends ChangeNotifier {
  static HymnAudioPack instance = HymnAudioPack();

  final HymnAudioStore _store;
  final http.Client _client;
  final Duration _timeout;
  List<AudioFile>? _files;

  HymnAudioPack({
    HymnAudioStore? store,
    http.Client? client,
    List<AudioFile>? files,
    Duration timeout = const Duration(seconds: 45),
  })  : _store = store ?? createHymnAudioStore(),
        _client = client ?? http.Client(),
        _files = files,
        _timeout = timeout;

  AudioPackState _state = AudioPackState.idle;
  bool _cancelled = false;
  bool _loaded = false;
  Set<String> _installed = {};

  AudioPackState get state => _state;
  bool get supported => _store.supported;
  bool get loaded => _loaded;

  List<AudioFile> get files => _files ?? const [];
  int get total => files.length;
  int get installed => _installed.length;
  int get totalBytes => files.fold(0, (a, f) => a + f.size);
  int get installedBytes =>
      files.where((f) => _installed.contains(f.name)).fold(0, (a, f) => a + f.size);
  bool get complete => total > 0 && installed == total;
  bool get downloading => _state == AudioPackState.downloading;

  Future<void>? _loadFuture;

  /// Charge une seule fois (les appels suivants attendent le même chargement).
  Future<void> ensureLoaded() => _loadFuture ??= load();

  /// Charge la liste des enregistrements (fichier fourni avec l'application) et
  /// regarde ce qui est déjà téléchargé.
  Future<void> load() async {
    _files ??= await _readManifest();
    await refresh();
    _loaded = true;
    notifyListeners();
  }

  static Future<List<AudioFile>> _readManifest() async {
    final raw = await rootBundle.loadString('assets/hymn_audio_manifest.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return [
      for (final f in data['files'] as List)
        AudioFile((f as Map)['name'] as String, f['size'] as int),
    ];
  }

  /// Recompte les fichiers présents et valides.
  Future<void> refresh() async {
    final found = <String>{};
    for (final f in files) {
      if (await _store.pathIfValid(f.name, f.size) != null) found.add(f.name);
    }
    _installed = found;
    notifyListeners();
  }

  /// Chemin local d'un enregistrement (`hymn_audio/6.m4a`) s'il a été téléchargé.
  Future<String?> localPath(String audioUrl) async {
    if (!_store.supported) return null;
    final name = audioUrl.split('/').last;
    final file = files.where((f) => f.name == name);
    if (file.isEmpty) {
      // Liste pas encore chargée : on la charge une fois.
      if (_files == null) {
        try {
          _files = await _readManifest();
        } catch (_) {
          return null;
        }
        return localPath(audioUrl);
      }
      return null;
    }
    return _store.pathIfValid(name, file.first.size);
  }

  String? _lastError;
  String? get lastError => _lastError;

  /// Lance (ou reprend) le téléchargement des enregistrements manquants.
  Future<void> start() async {
    if (!_store.supported || downloading) return;
    if (_files == null) await load();
    _state = AudioPackState.downloading;
    _cancelled = false;
    _lastError = null;
    notifyListeners();
    try {
      await refresh();
      for (final f in files) {
        if (_cancelled) break;
        if (_installed.contains(f.name)) continue;
        final ok = await _fetch(f);
        if (_cancelled) break;
        if (!ok) {
          _lastError = 'network';
          _state = AudioPackState.error;
          notifyListeners();
          return;
        }
        _installed = {..._installed, f.name};
        notifyListeners();
      }
      _state = AudioPackState.idle;
    } catch (e) {
      _lastError = e.toString();
      _state = AudioPackState.error;
    }
    notifyListeners();
  }

  Future<bool> _fetch(AudioFile f) async {
    for (final url in HymnAudio.candidates(f.audioUrl)) {
      try {
        final response = await _client.get(Uri.parse(url)).timeout(_timeout);
        if (_cancelled) return true;
        if (response.statusCode == 200 && response.bodyBytes.length == f.size) {
          await _store.write(f.name, response.bodyBytes);
          return true;
        }
      } catch (_) {
        // Adresse suivante, puis échec.
      }
    }
    return false;
  }

  /// Arrête le téléchargement (les fichiers déjà reçus sont gardés).
  void cancel() {
    if (!downloading) return;
    _cancelled = true;
  }

  /// Supprime les enregistrements téléchargés.
  Future<void> remove() async {
    cancel();
    await _store.clear();
    _installed = {};
    _state = AudioPackState.idle;
    _lastError = null;
    notifyListeners();
  }
}

/// « 81 Mo » (français) ou « 81 MB » (swahili), arrondi au Mo.
String formatMegabytes(int bytes, String locale) {
  final mb = (bytes / (1024 * 1024)).round();
  return '$mb ${locale == 'sw' ? 'MB' : 'Mo'}';
}
