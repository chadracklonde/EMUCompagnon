import 'package:package_info_plus/package_info_plus.dart';

import '../../core/l10n/app_strings.dart';
import 'text_share_service.dart';

/// « Recommander l'application » : partage, par les applications de messagerie,
/// un court message et le lien de la fiche Play Store.
class AppShareService {
  /// Identifiant de l'application sur le Play Store, utilisé seulement si
  /// l'appareil ne le donne pas (le vrai est lu au moment du partage).
  static const fallbackPackageId = 'com.emucompagnon.emu_compagnon';

  static String playStoreUrl(String packageId) =>
      'https://play.google.com/store/apps/details?id=$packageId';

  /// Le message partagé, dans la langue de l'application.
  static String message(String locale, String url) =>
      AppStrings.tf('recommend_message', locale, {'url': url});

  static Future<String> _packageId() async {
    try {
      final id = (await PackageInfo.fromPlatform()).packageName;
      // Sur ordinateur ou sur le web, ce n'est pas un identifiant Play Store.
      if (id.contains('.')) return id;
    } catch (_) {}
    return fallbackPackageId;
  }

  static Future<void> recommend(String locale) async {
    final url = playStoreUrl(await _packageId());
    await TextShareService.share(
      message(locale, url),
      subject: AppStrings.t('recommend_subject', locale),
    );
  }
}
