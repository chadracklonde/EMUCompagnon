import 'hymn_audio_store.dart';

/// Stockage sans fichiers (web) : rien n'est téléchargeable.
class UnsupportedHymnAudioStore implements HymnAudioStore {
  const UnsupportedHymnAudioStore();

  @override
  bool get supported => false;

  @override
  Future<String?> pathIfValid(String name, int size) async => null;

  @override
  Future<void> write(String name, List<int> bytes) async =>
      throw UnsupportedError('Pas de stockage de fichiers sur cette plateforme.');

  @override
  Future<void> clear() async {}
}

HymnAudioStore createHymnAudioStore() => const UnsupportedHymnAudioStore();
