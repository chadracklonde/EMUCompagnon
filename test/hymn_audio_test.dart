import 'package:emu_compagnon/shared/widgets/hymn_audio_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un chemin relatif est essayé sur main puis sur la branche de travail', () {
    final urls = HymnAudio.candidates('hymn_audio/6.m4a');
    expect(urls, [
      '${HymnAudio.mainUrl}hymn_audio/6.m4a',
      '${HymnAudio.branchUrl}hymn_audio/6.m4a',
    ]);
    expect(urls.first, contains('/EMUCompagnon/main/'));
    expect(HymnAudio.mainUrl.endsWith('/'), isTrue);
    expect(HymnAudio.branchUrl.endsWith('/'), isTrue);
  });

  test('une adresse complète est gardée telle quelle', () {
    expect(HymnAudio.candidates('https://exemple.org/a.mp3'), ['https://exemple.org/a.mp3']);
  });
}
