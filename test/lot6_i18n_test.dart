import 'package:emu_compagnon/core/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sauvegarde, mises à jour du contenu et widgets : français et swahili', () {
    const keys = [
      'bk_days_ago',
      'bk_done',
      'bk_done_body',
      'bk_export',
      'bk_fail',
      'bk_import',
      'bk_info',
      'bk_never',
      'bk_share_text',
      'bk_title',
      'bk_today',
      'bk_warn',
      'bk_yesterday',
      'cu_bad',
      'cu_check',
      'cu_checking',
      'cu_current',
      'cu_dl_fail',
      'cu_info',
      'cu_last',
      'cu_no_net',
      'cu_title',
      'cu_updated',
      'cu_version',
      'wg_android',
      'wg_confirm',
      'wg_count',
      'wg_how',
      'wg_manual',
      'wg_none',
      'wg_title',
    ];
    for (final key in keys) {
      final fr = AppStrings.t(key, 'fr');
      final sw = AppStrings.t(key, 'sw');
      expect(fr, isNot(key), reason: 'fr $key');
      expect(sw, isNot(key), reason: 'sw $key');
      expect(sw, isNot(fr), reason: 'sw = fr pour $key');
    }
  });

  test('les marqueurs des textes dynamiques sont présents dans les deux langues', () {
    const placeholders = {
      'bk_days_ago': ['{n}'],
      'bk_done_body': ['{b}', '{n}', '{h}', '{m}', '{j}', '{e}'],
      'bk_share_text': ['{stamp}'],
      'cu_current': ['{v}'],
      'cu_updated': ['{v}'],
      'wg_count': ['{n}'],
    };
    placeholders.forEach((key, marks) {
      for (final locale in ['fr', 'sw']) {
        final text = AppStrings.t(key, locale);
        for (final mark in marks) {
          expect(text, contains(mark), reason: '$locale $key');
        }
      }
    });
  });

  test('les messages de mise à jour suivent la langue demandée', () {
    expect(AppStrings.tf('cu_updated', 'fr', {'v': 3}), 'Contenu mis à jour vers la version 3 !');
    expect(AppStrings.tf('cu_updated', 'sw', {'v': 3}), 'Maudhui yamesasishwa hadi toleo 3!');
  });
}
