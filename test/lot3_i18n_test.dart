import 'package:emu_compagnon/core/l10n/app_strings.dart';
import 'package:emu_compagnon/core/models/highlight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('menu des cantiques, textes de l\'Église, notes et surlignage : français et swahili', () {
    const keys = [
      'ct_pinned', 'ct_unpinned', 'ct_unpin', 'ct_pin', 'ct_share_passage', 'ct_copy_passage',
      'ct_copied', 'ct_contents', 'more_actions', 'ct_share_all', 'to_top', 'ct_original',
      'ct_long_press', 'ct_long_press_hint', 'ct_leader', 'ct_people', 'ctl_title', 'ctl_search',
      'clear', 'ctl_none', 'hd_unfav', 'hd_fav', 'hd_key', 'hd_add_list', 'hd_notes',
      'hd_share_text', 'hd_share_image', 'nt_title', 'nt_none', 'nt_edit', 'nt_delete',
      'nt_hint_edit', 'nt_hint_new', 'nt_update', 'nt_today', 'hi_title', 'hi_in', 'hi_remove',
    ];
    for (final key in keys) {
      final fr = AppStrings.t(key, 'fr');
      final sw = AppStrings.t(key, 'sw');
      expect(fr, isNot(key), reason: 'fr $key');
      expect(sw, isNot(key), reason: 'sw $key');
      expect(sw, isNot(fr), reason: 'sw = fr pour $key');
    }
  });

  test('chaque couleur de surlignage a un nom dans les deux langues', () {
    for (final name in HighlightColors.palette.keys) {
      expect(AppStrings.t('hi_c_$name', 'fr'), isNot('hi_c_$name'));
      expect(AppStrings.t('hi_c_$name', 'sw'), isNot('hi_c_$name'));
    }
  });
}
