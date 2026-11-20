import 'package:emu_compagnon/core/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('journal, plan de lecture, mémorisation, examen du soir, défi : français et swahili', () {
    const keys = [
      'ex_answer',
      'ex_filled',
      'ex_intro',
      'ex_saved',
      'ex_title',
      'jr_delete_body',
      'jr_delete_q',
      'jr_edit',
      'jr_empty',
      'jr_hint',
      'jr_new',
      'jr_title',
      'mm_add',
      'mm_add_title',
      'mm_again',
      'mm_book',
      'mm_chapter',
      'mm_easy',
      'mm_empty',
      'mm_err_dup',
      'mm_err_nf',
      'mm_err_num',
      'mm_good',
      'mm_hard',
      'mm_how',
      'mm_mine',
      'mm_n_due',
      'mm_next',
      'mm_none_due',
      'mm_one_due',
      'mm_remove',
      'mm_review',
      'mm_show',
      'mm_title',
      'mm_verse',
      'rp_apply',
      'rp_ask_all',
      'rp_ask_rest',
      'rp_avg',
      'rp_change',
      'rp_day',
      'rp_day1',
      'rp_day_detail',
      'rp_day_line',
      'rp_day_read',
      'rp_days_1',
      'rp_days_hint',
      'rp_days_n',
      'rp_days_suffix',
      'rp_done',
      'rp_duration',
      'rp_max',
      'rp_min1',
      'rp_month1',
      'rp_months3',
      'rp_months6',
      'rp_next',
      'rp_one_chapter',
      'rp_per_day',
      'rp_pick',
      'rp_plan_on',
      'rp_read_time',
      'rp_reset',
      'rp_reset_body',
      'rp_reset_q',
      'rp_title',
      'rp_week',
      'rp_year',
      'wc_done',
      'wc_new',
      'wc_this_week',
      'wc_title',
    ];
    for (final key in keys) {
      final fr = AppStrings.t(key, 'fr');
      final sw = AppStrings.t(key, 'sw');
      expect(fr, isNot(key), reason: 'fr $key');
      expect(sw, isNot(key), reason: 'sw $key');
      // Les noms propres ou chiffres seuls peuvent rester identiques.
      if (!{'mm_good'}.contains(key)) {
        expect(sw, isNot(fr), reason: 'sw = fr pour $key');
      }
    }
  });

  test('les marqueurs des textes dynamiques sont présents dans les deux langues', () {
    const placeholders = {
      'rp_plan_on': ['{days}'],
      'rp_avg': ['{n}', '{time}'],
      'rp_next': ['{n}', '{label}'],
      'rp_day_detail': ['{c}', '{v}', '{time}'],
      'rp_max': ['{days}', '{n}'],
      'mm_n_due': ['{n}'],
      'mm_mine': ['{n}'],
      'mm_next': ['{date}'],
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
}
