import 'package:emu_compagnon/core/l10n/app_strings.dart';
import 'package:emu_compagnon/features/hymn_lists/widgets/list_dialogs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque texte des listes de cantiques existe en français et en swahili', () {
    for (final key in ['hl_title', 'hl_intro', 'hl_empty', 'hl_add_to', 'hl_count_n', 'hl_next_up']) {
      expect(AppStrings.t(key, 'fr'), isNot(key), reason: 'fr $key');
      expect(AppStrings.t(key, 'sw'), isNot(key), reason: 'sw $key');
      expect(AppStrings.t(key, 'sw'), isNot(AppStrings.t(key, 'fr')), reason: 'sw = fr pour $key');
    }
  });

  test('le nom proposé pour une liste suit la langue', () {
    final sunday = DateTime(2026, 11, 22);
    expect(suggestedListName(sunday), 'Culte du 22 novembre');
    expect(suggestedListName(sunday, 'sw'), 'Ibada ya 22 Novemba');
    expect(suggestedListName(DateTime(2026, 11, 1)), 'Culte du 1er novembre');
  });
}
