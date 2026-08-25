import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/db_helper.dart';

/// Lets the app fetch an updated Bible/hymns/dictionary database without
/// going through an app-store release — useful for fixing content typos
/// or expanding the dictionary later. Reads a small JSON manifest hosted
/// in the project's own GitHub repo (raw.githubusercontent.com), and only
/// downloads the full database if its version number increased.
///
/// Requires the GitHub repo to be public (raw.githubusercontent.com
/// cannot serve files from a private repo without extra auth this app
/// does not implement). To publish a content update: bump "version" in
/// content_version.json at the repo root and push a newer app_data.db to
/// assets/db/ in the same commit.
class ContentUpdateService {
  static const _manifestUrl =
      'https://raw.githubusercontent.com/chadracklonde/EMUCompagnon/main/content_version.json';
  static const _kLocalVersion = 'content.localVersion';
  static const _kLastChecked = 'content.lastChecked';

  static Future<int> getLocalVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kLocalVersion) ?? 1;
  }

  static Future<DateTime?> getLastChecked() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastChecked);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Returns the remote manifest, or null if it couldn't be fetched
  /// (offline, repo not public yet, etc.) — callers should treat that as
  /// "no update available right now", not an error to alarm the user with.
  static Future<Map<String, dynamic>?> _fetchManifest() async {
    try {
      final response = await http
          .get(Uri.parse(_manifestUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Checks for an update and, if one is available, downloads and merges
  /// it. Returns a human-readable result message for display.
  static Future<String> checkAndApplyUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastChecked, DateTime.now().toIso8601String());

    final manifest = await _fetchManifest();
    if (manifest == null) {
      return "Impossible de vérifier les mises à jour (pas de connexion, ou dépôt pas encore public).";
    }

    final remoteVersion = manifest['version'] as int?;
    final dbUrl = manifest['db_url'] as String?;
    if (remoteVersion == null || dbUrl == null) {
      return "Fichier de version distant invalide.";
    }

    final localVersion = await getLocalVersion();
    if (remoteVersion <= localVersion) {
      return "Contenu déjà à jour (version $localVersion).";
    }

    final response = await http.get(Uri.parse(dbUrl)).timeout(const Duration(minutes: 2));
    if (response.statusCode != 200) {
      return "Échec du téléchargement de la mise à jour.";
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/content_update.db');
    await tempFile.writeAsBytes(response.bodyBytes, flush: true);

    await DbHelper.mergeContentUpdate(tempFile.path);
    await tempFile.delete();

    await prefs.setInt(_kLocalVersion, remoteVersion);
    return "Contenu mis à jour vers la version $remoteVersion !";
  }
}
