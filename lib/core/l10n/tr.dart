import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../settings/app_settings.dart';
import 'app_strings.dart';

/// Raccourci pour les écrans : `context.tr('clé')` donne le texte dans la
/// langue de l'application et se met à jour quand on change de langue.
extension TrContext on BuildContext {
  /// Langue de l'application (`fr` ou `sw`).
  String get lang => Provider.of<AppSettings>(this).locale;

  String tr(String key) =>
      AppStrings.t(key, Provider.of<AppSettings>(this).locale);

  String trf(String key, Map<String, Object> values) =>
      AppStrings.tf(key, Provider.of<AppSettings>(this).locale, values);
}
