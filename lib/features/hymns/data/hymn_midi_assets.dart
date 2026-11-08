// Cantiques dont la mélodie dispose d'un fichier MIDI libre de droits.
// Source : Christian Classics Ethereal Hymnary (voir assets/midi/ccel/LICENSE-CCEH.txt).
// Clé : numéro du cantique tel que stocké dans la table `hymns`.
// Chaque association a été vérifiée en comparant le contour mélodique avec
// une autre version de la mélodie (voir docs/midi-candidats-ccel/README.md).
const Map<String, String> hymnMidiFiles = {
  '187': 'ein_feste_burg.mid', // C'est un rempart !
  '233': 'el_nathan.mid', // Je ne sais pourquoi
  '234': 'converse.mid', // Quel ami fidèle et tendre
  '279': 'dennis.mid', // Béni soit le lien
  '400': 'dennis.mid', // Béni soit le lien (doublon du 279)
};

/// Chemin d'asset du MIDI du cantique [number], ou null s'il n'en a pas.
String? hymnMidiAssetFor(String number) {
  final file = hymnMidiFiles[number.trim().replaceFirst(RegExp(r'^0+'), '')];
  return file == null ? null : 'assets/midi/ccel/$file';
}
