import 'package:emu_compagnon/core/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque texte de Réglages et À propos existe en français et en swahili', () {
    const keys = [
      'st_title', 'st_appearance', 'st_lang', 'st_lang_hint', 'st_theme', 'st_system',
      'st_light', 'st_dark', 'st_reading', 'st_text_size', 'st_text_size_hint', 'st_line',
      'st_line_hint', 'st_font', 'st_preview', 'st_awake', 'st_awake_hint', 'st_reminder',
      'st_reminder_on', 'st_reminder_hint', 'st_reminder_time', 'st_perm_denied', 'st_reset',
      'ab_title', 'ab_photo', 'ab_role', 'ab_bio', 'ab_contact', 'ab_resources',
      'ab_resourceumc', 'ab_official_page', 'ab_official_channel', 'ab_footer',
    ];
    for (final key in keys) {
      final fr = AppStrings.t(key, 'fr');
      final sw = AppStrings.t(key, 'sw');
      expect(fr, isNot(key), reason: 'fr $key');
      expect(sw, isNot(key), reason: 'sw $key');
      expect(sw, isNot(fr), reason: 'sw = fr pour $key');
    }
  });

  test('le texte de la langue ne promet plus un contenu « bientôt traduit »', () {
    expect(AppStrings.t('st_lang_hint', 'fr'), isNot(contains('non encore disponible')));
  });
}
