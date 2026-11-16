import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import 'onboarding_screen.dart';

/// Premier écran de l'application, une seule fois, aux nouvelles
/// installations : le choix de la langue. Le tutoriel qui suit est dans la
/// langue choisie. Le nom de chaque langue est écrit dans cette langue.
class LanguageWelcomeScreen extends StatefulWidget {
  /// Langue présélectionnée ; par défaut celle du téléphone (swahili si le
  /// téléphone est en swahili, français sinon).
  final String? initialLocale;
  const LanguageWelcomeScreen({super.key, this.initialLocale});

  /// La langue du téléphone, ramenée à celles de l'application.
  static String deviceLocale() {
    final locales = WidgetsBinding.instance.platformDispatcher.locales;
    for (final l in locales) {
      if (l.languageCode == 'sw') return 'sw';
      if (l.languageCode == 'fr') return 'fr';
    }
    return 'fr';
  }

  @override
  State<LanguageWelcomeScreen> createState() => _LanguageWelcomeScreenState();
}

class _LanguageWelcomeScreenState extends State<LanguageWelcomeScreen> {
  late String _choice;
  late final String _device;

  @override
  void initState() {
    super.initState();
    _device = LanguageWelcomeScreen.deviceLocale();
    _choice = widget.initialLocale ?? _device;
  }

  Future<void> _continue() async {
    final settings = context.read<AppSettings>();
    final navigator = Navigator.of(context);
    await settings.setLocale(_choice);
    if (!mounted) return;
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    String t(String key) => AppStrings.t(key, _choice);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Karibu · Bienvenue',
                    style: TextStyle(
                      fontSize: 30,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chagua lugha · Choisissez votre langue',
                    style: TextStyle(fontSize: 16, color: palette.muted),
                  ),
                  const SizedBox(height: 28),
                  _LanguageCard(
                    name: 'Kiswahili',
                    detail: 'Biblia Takatifu Wazi · Nyimbo za Wokovu',
                    note: _device == 'sw' ? AppStrings.t('welcome_phone_lang', 'sw') : null,
                    selected: _choice == 'sw',
                    onTap: () => setState(() => _choice = 'sw'),
                  ),
                  const SizedBox(height: 12),
                  _LanguageCard(
                    name: 'Français',
                    detail: 'Louis Segond 1910 · Chants de Victoire',
                    note: _device == 'fr' ? AppStrings.t('welcome_phone_lang', 'fr') : null,
                    selected: _choice == 'fr',
                    onTap: () => setState(() => _choice = 'fr'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _continue,
                      child: Text(
                        t('welcome_continue'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t('welcome_later'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: palette.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String name;
  final String detail;
  final String? note;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageCard({
    required this.name,
    required this.detail,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$name, $detail',
      excludeSemantics: true,
      child: Material(
        color: selected ? palette.accentSoft : palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? palette.accent : palette.border, width: selected ? 2 : 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (note != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              note!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: palette.accent,
                              ),
                            ),
                          ),
                        Text(
                          name,
                          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: scheme.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(detail, style: TextStyle(fontSize: 13, color: palette.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    selected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: selected ? palette.accent : palette.muted,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
