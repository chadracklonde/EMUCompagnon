import 'package:emu_compagnon/features/hymns/utils/hymn_stanza_parser.dart';
import 'package:emu_compagnon/shared/services/text_share_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a verse is followed by its reference', () {
    expect(
      TextShareService.verseText(reference: 'Jean 11.35', text: ' Jésus pleura. '),
      'Jésus pleura.\n— Jean 11.35\n\nÉMU Compagnon',
    );
  });

  test('a hymn lists its stanzas and names the refrain', () {
    final text = TextShareService.hymnText(
      number: '12',
      title: 'À toi la gloire',
      stanzas: const [
        HymnStanza(label: '1', body: 'À toi la gloire,\nÔ Ressuscité !'),
        HymnStanza(label: 'Chœur', body: 'À toi la victoire', isRefrain: true),
        HymnStanza(label: '2', body: 'Vois-le paraître'),
      ],
    );
    expect(
      text,
      '12 — À toi la gloire\n'
      '\n1.\nÀ toi la gloire,\nÔ Ressuscité !\n'
      '\nRefrain\nÀ toi la victoire\n'
      '\n2.\nVois-le paraître\n'
      '\nÉMU Compagnon',
    );
  });

  test('a hymn without parsed stanzas still has its title', () {
    expect(
      TextShareService.hymnText(number: '3', title: 'Titre', stanzas: const []),
      '3 — Titre\n\nÉMU Compagnon',
    );
  });
}
