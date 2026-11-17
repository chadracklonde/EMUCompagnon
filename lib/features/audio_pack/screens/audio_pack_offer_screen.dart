import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../hymn_audio_pack.dart';
import '../widgets/audio_pack_card.dart';

/// La proposition faite une seule fois, au début : télécharger les
/// enregistrements pour écouter les cantiques sans connexion. Le même bloc
/// reste dans les Réglages, pour le faire plus tard.
class AudioPackOffer {
  static const _kShown = 'audioPack.offerShown';

  /// Faut-il la proposer maintenant ? Une fois par installation, en français
  /// (les enregistrements sont ceux des Chants de Victoire) et seulement sur un
  /// appareil qui peut garder des fichiers.
  static Future<bool> shouldShow(String locale, {HymnAudioPack? pack}) async {
    if (locale != 'fr') return false;
    if (!(pack ?? HymnAudioPack.instance).supported) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kShown) ?? false);
  }

  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShown, true);
  }
}

class AudioPackOfferScreen extends StatefulWidget {
  /// L'écran qui suit (l'application), construit quand on continue.
  final WidgetBuilder next;
  final HymnAudioPack? pack;
  const AudioPackOfferScreen({super.key, required this.next, this.pack});

  @override
  State<AudioPackOfferScreen> createState() => _AudioPackOfferScreenState();
}

class _AudioPackOfferScreenState extends State<AudioPackOfferScreen> {
  HymnAudioPack get _pack => widget.pack ?? HymnAudioPack.instance;

  @override
  void initState() {
    super.initState();
    _pack.load();
    AudioPackOffer.markShown();
  }

  void _continue() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: widget.next));
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppSettings>().locale;
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    String t(String key, [Map<String, Object> v = const {}]) => AppStrings.tf(key, locale, v);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: ListenableBuilder(
                listenable: _pack,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: palette.accentSoft,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(Icons.library_music_outlined, color: palette.accent, size: 44),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      t('audio_pack_offer_title'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('audio_pack_desc', {
                        'n': _pack.total,
                        'size': formatMegabytes(_pack.totalBytes, locale),
                      }),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15.5, height: 1.5, color: palette.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('audio_pack_for_cv'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: palette.muted),
                    ),
                    const SizedBox(height: 24),
                    AudioPackCard(pack: _pack, bare: true),
                    if (_pack.downloading) ...[
                      const SizedBox(height: 8),
                      Text(
                        t('audio_pack_background'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: palette.muted),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: _pack.downloading || _pack.complete
                          ? FilledButton(
                              onPressed: _continue,
                              child: Text(t('audio_pack_continue'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            )
                          : TextButton(
                              onPressed: _continue,
                              child: Text(t('audio_pack_later'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
