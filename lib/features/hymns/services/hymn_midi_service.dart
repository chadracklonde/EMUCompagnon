import 'package:flutter/foundation.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

/// Lecture des fichiers MIDI des cantiques via le synthé SoundFont
/// (flutter_midi_pro). Le lecteur de fichiers MIDI du plugin n'existe pour
/// l'instant que sur Android : ailleurs, [isSupported] est false et l'UI
/// n'affiche simplement pas le lecteur.
class HymnMidiService {
  HymnMidiService._();
  static final HymnMidiService instance = HymnMidiService._();

  static const soundfontAsset = 'assets/soundfonts/GeneralUser-GS.sf2';

  final MidiPro _midi = MidiPro();
  Future<int>? _soundfontId;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Initialise le synthé et charge la soundfont une seule fois.
  Future<int> _ensureReady() => _soundfontId ??= _init().catchError((Object e) {
        _soundfontId = null; // permet de réessayer
        throw e;
      });

  Future<int> _init() async {
    await _midi.init();
    return _midi.loadSoundfontAsset(assetPath: soundfontAsset);
  }

  /// Charge un MIDI (remplace le précédent) et le positionne au début.
  Future<void> load(String assetPath) async {
    final sfId = await _ensureReady();
    await _midi.stopMidi();
    await _midi.loadMidiAsset(assetPath: assetPath, sfId: sfId);
    await _midi.setMidiLoop(0);
    await _midi.setMidiTempo(1.0);
  }

  Future<void> play() => _midi.playMidi();
  Future<void> pause() => _midi.pauseMidi();
  Future<void> stop() async {
    await _midi.stopMidi();
    await _midi.seekMidi(0);
  }

  Future<void> seek(int tick) => _midi.seekMidi(tick);
  Future<void> setTempo(double factor) => _midi.setMidiTempo(factor);

  /// -1 = boucle infinie, 0 = lecture unique.
  Future<void> setLoop(bool loop) => _midi.setMidiLoop(loop ? -1 : 0);

  Future<MidiPlayerState> state() => _midi.getMidiPlayerState();

  /// Arrête le son (changement d'écran) sans libérer le synthé.
  Future<void> halt() async {
    if (_soundfontId == null) return;
    try {
      await _midi.stopMidi();
      await _midi.stopAllNotes(sfId: await _soundfontId!);
    } catch (_) {}
  }
}
