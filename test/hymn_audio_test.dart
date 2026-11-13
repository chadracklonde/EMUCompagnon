import 'package:emu_compagnon/shared/widgets/hymn_audio_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un chemin relatif est complété, une adresse complète est gardée', () {
    expect(HymnAudio.resolve('hymn_audio/6.m4a'), '${HymnAudio.baseUrl}hymn_audio/6.m4a');
    expect(HymnAudio.resolve('https://exemple.org/a.mp3'), 'https://exemple.org/a.mp3');
    expect(HymnAudio.baseUrl.endsWith('/'), isTrue);
  });
}
