import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';

/// Un des deux choix du sélecteur : la langue (`fr` ou `sw`), son libellé et,
/// sous le libellé, une précision (la langue, quand le libellé est le nom d'un
/// recueil ou d'une version de la Bible).
class LanguageOption {
  final String locale;
  final String label;
  final String? caption;
  const LanguageOption(this.locale, this.label, [this.caption]);
}

/// Le sélecteur de langue de l'application : une barre à deux positions dont
/// le curseur glisse sous le choix en cours (dessin « commutateur »).
///
/// Un seul réglage derrière tous ses emplacements : la langue de l'interface,
/// la Bible et le recueil de cantiques changent ensemble (voir `AppSettings`).
/// Après un changement, une bannière propose d'annuler.
class LanguageSwitch extends StatelessWidget {
  final List<LanguageOption> options;

  /// Version à une ligne (accueil) ; sinon le libellé est suivi de sa précision.
  final bool compact;

  const LanguageSwitch({super.key, required this.options, this.compact = false});

  /// Hauteurs de la barre : au moins 48 dp, la zone de toucher recommandée.
  static const compactHeight = 48.0;
  static const fullHeight = 58.0;

  /// Le nom d'une langue, toujours écrit dans cette langue : un lecteur du
  /// swahili le reconnaît même dans une interface en français.
  static String languageName(String locale) => locale == 'sw' ? 'Kiswahili' : 'Français';

  /// Les deux langues, pour l'accueil.
  static const languages = [
    LanguageOption('fr', 'Français'),
    LanguageOption('sw', 'Kiswahili'),
  ];

  /// Les deux recueils de cantiques.
  static const hymnals = [
    LanguageOption('fr', 'Chants de Victoire', 'Français'),
    LanguageOption('sw', 'Nyimbo za Wokovu', 'Kiswahili'),
  ];

  /// Les deux versions de la Bible.
  static const bibles = [
    LanguageOption('fr', 'Louis Segond 1910', 'Français'),
    LanguageOption('sw', 'Biblia Takatifu Wazi', 'Kiswahili'),
  ];

  Future<void> _select(BuildContext context, AppSettings settings, String locale) async {
    if (settings.locale == locale) return;
    final previous = settings.locale;
    await settings.setLocale(locale);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(AppStrings.tf('lang_changed', locale, {'name': languageName(locale)})),
        action: SnackBarAction(
          label: AppStrings.t('undo', locale),
          onPressed: () => settings.setLocale(previous),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    assert(options.length == 2, 'Le sélecteur a exactement deux choix.');
    final settings = context.watch<AppSettings>();
    final palette = AppPalette.of(context);
    final height = compact ? compactHeight : fullHeight;
    final selected = options.indexWhere((o) => o.locale == settings.locale);
    final index = selected < 0 ? 0 : selected;
    final onAccent = ThemeData.estimateBrightnessForColor(palette.accent) == Brightness.dark
        ? Colors.white
        : const Color(0xFF1D1214);
    final animate = !MediaQuery.of(context).disableAnimations;

    return Semantics(
      container: true,
      label: AppStrings.t('lang_switch', settings.locale),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: palette.accentSoft,
          borderRadius: BorderRadius.circular(height / 2.6),
          border: Border.all(color: palette.border),
        ),
        child: Stack(
          children: [
            // Le curseur : sa position dit, sans la couleur, quelle langue est en cours.
            AnimatedAlign(
              duration: animate ? const Duration(milliseconds: 220) : Duration.zero,
              curve: Curves.easeOutCubic,
              alignment: index == 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(height / 2.6 - 3),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == index,
                      label: [options[i].label, if (options[i].caption != null) options[i].caption!].join(', '),
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(height / 2.6 - 3),
                        onTap: () => _select(context, settings, options[i].locale),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                options[i].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: compact ? 14.5 : 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  color: i == index ? onAccent : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              if (!compact && options[i].caption != null)
                                Text(
                                  options[i].caption!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.2,
                                    color: i == index
                                        ? onAccent.withValues(alpha: 0.85)
                                        : palette.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
