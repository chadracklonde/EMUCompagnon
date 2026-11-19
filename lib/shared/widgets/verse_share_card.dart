import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import 'google_play_badge.dart';

/// Le visuel capturé en image quand on partage un verset (ou un extrait de
/// cantique) : le même que celui des publications de la page. Fond crème, nom
/// de l'application en haut, le texte en grand, sa référence et sa source,
/// puis un bandeau rouge qui invite à télécharger l'application sur Google Play.
///
/// Il garde ses couleurs en mode sombre : c'est une image destinée à d'autres
/// personnes, pas un écran de l'application.
class VerseShareCard extends StatelessWidget {
  /// Dimensions logiques ; capturé à 2×, le fichier fait 1080 × 1350 (4:5).
  static const width = 540.0;
  static const height = 675.0;

  /// Adresse affichée en bas (sans « https:// », plus courte à lire).
  static const playStoreDisplay =
      'play.google.com/store/apps/details?id=com.emucompagnon.emu_compagnon';

  static const _cream = Color(0xFFFAF6F1);
  static const _burgundy = Color(0xFF8F1D26);
  static const _verseColor = Color(0xFF6E131B);
  static const _ink = Color(0xFF3A1217);
  static const _gold = Color(0xFFB5832A);
  static const _goldBright = Color(0xFFF2AC1A);
  static const _muted = Color(0xFF8A7A74);
  static const _urlColor = Color(0xFFFFD77A);

  final String reference;
  final String text;

  /// Le petit titre en capitales au-dessus du texte (« Verset du jour »…).
  final String label;

  /// D'où vient le texte : la version de la Bible, ou le recueil de cantiques.
  final String? source;

  /// Langue du visuel (`fr` ou `sw`) : invitation et badge.
  final String locale;

  const VerseShareCard({
    super.key,
    required this.reference,
    required this.text,
    required this.label,
    this.source,
    this.locale = 'fr',
  });

  /// La source à indiquer pour une version de la Bible. La Biblia Takatifu Wazi
  /// porte sa mention de licence (CC BY-SA 4.0), qui doit suivre le texte.
  static String sourceForBible(String versionCode) => versionCode == 'SCV'
      ? 'Biblia Takatifu Wazi © Biblica, 2018 · CC BY-SA 4.0'
      : 'Louis Segond 1910';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: _cream,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Container(height: 7, color: _burgundy),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 26, 32, 0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          Container(width: 42, height: 42, color: _burgundy),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ÉMU Compagnon',
                    style: TextStyle(
                      color: _burgundy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(44, 8, 44, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(width: 50, height: 2.5, color: _goldBright),
                    const SizedBox(height: 22),
                    // Le texte garde sa taille s'il tient, sinon il rétrécit :
                    // un verset court et un couplet entier tiennent tous deux.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: width - 88,
                          child: Text(
                            '« ${text.trim()} »',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _verseColor,
                              fontSize: 34,
                              height: 1.3,
                              fontFamily: 'PlayfairDisplay',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      reference,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (source != null && source!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        source!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _muted, fontSize: 11.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: _burgundy,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.t('share_cta', locale),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GooglePlayBadge(topLine: AppStrings.t('share_badge_top', locale)),
                  const SizedBox(height: 12),
                  const Text(
                    playStoreDisplay,
                    style: TextStyle(
                      color: _urlColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
