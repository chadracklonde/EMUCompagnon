import 'package:emu_compagnon/core/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('liturgie, culte du dimanche, favoris et recherche : français et swahili', () {
    const keys = [
      'fv_hymns',
      'fv_none_hymn',
      'fv_none_note',
      'fv_none_verse',
      'fv_notes',
      'fv_title',
      'fv_verses',
      'gs_bible',
      'gs_dict',
      'gs_hint',
      'gs_hymns',
      'gs_lit',
      'gs_none',
      'gs_none_lit',
      'gs_recent',
      'lg_bow_texts',
      'lg_cal',
      'lg_cal_sub',
      'lg_explore',
      'lg_order',
      'lg_order_basic_sub',
      'lg_order_sub',
      'lg_sacr',
      'lg_sacr_sub',
      'lg_texts_sub',
      'lg_worship',
      'lg_worship_sub',
      'wo_all_texts',
      'wo_choose',
      'wo_date',
      'wo_empty_list',
      'wo_flow',
      'wo_hymns',
      'wo_lists_avail',
      'wo_manage',
      'wo_n_hymns',
      'wo_next',
      'wo_prayers',
      'wo_prepare',
      'wo_prepare_service',
      'wo_prepare_sub',
      'wo_special',
      'wo_start',
      'wo_today',
    ];
    for (final key in keys) {
      final fr = AppStrings.t(key, 'fr');
      final sw = AppStrings.t(key, 'sw');
      expect(fr, isNot(key), reason: 'fr $key');
      expect(sw, isNot(key), reason: 'sw $key');
      expect(sw, isNot(fr), reason: 'sw = fr pour $key');
    }
  });

  test('la date du culte du dimanche suit la langue', () {
    expect(
      AppStrings.tf('wo_date', 'fr', {'d': 22, 'm': AppStrings.monthName(11, 'fr'), 'y': 2026}),
      'Dimanche 22 novembre 2026',
    );
    expect(
      AppStrings.tf('wo_date', 'sw', {'d': 22, 'm': AppStrings.monthName(11, 'sw'), 'y': 2026}),
      'Jumapili 22 Novemba 2026',
    );
  });
}
