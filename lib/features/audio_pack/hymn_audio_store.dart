/// Où sont rangés les enregistrements téléchargés. Sur le web, il n'y a pas de
/// dossier : le stockage est « non pris en charge » et l'écoute reste en ligne.
export 'hymn_audio_store_stub.dart' if (dart.library.io) 'hymn_audio_store_io.dart';

abstract class HymnAudioStore {
  /// Faux quand l'appareil ne peut pas garder de fichiers (web).
  bool get supported;

  /// Chemin du fichier [name] s'il est là avec exactement [size] octets, sinon null.
  Future<String?> pathIfValid(String name, int size);

  /// Écrit le fichier [name] d'un seul coup (via un fichier temporaire renommé :
  /// un téléchargement interrompu ne laisse jamais un fichier à moitié écrit).
  Future<void> write(String name, List<int> bytes);

  /// Supprime tous les enregistrements téléchargés.
  Future<void> clear();
}
