import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/settings/app_settings.dart';
import '../widgets/verse_share_card.dart';
import 'app_share_service.dart';

/// Renders a [VerseShareCard] off-screen, captures it as a PNG, and opens
/// the native share sheet. The picture carries the branded design with the
/// Google Play invitation; the accompanying text repeats the link.
///
/// Deliberately platform-agnostic (no dart:io, no path_provider): the
/// captured PNG bytes are handed to share_plus directly via
/// `XFile.fromData`, which works in memory on every platform including
/// the web, where there is no real filesystem to write a temp file to.
class ImageShareService {
  /// La langue de l'application, `fr` si aucun réglage n'est disponible.
  static String _locale(BuildContext context) {
    try {
      return Provider.of<AppSettings>(context, listen: false).locale;
    } catch (_) {
      return 'fr';
    }
  }

  static Future<void> shareVerse(
    BuildContext context, {
    required String reference,
    required String text,
    /// Titre au-dessus du texte ; par défaut « Verset » / « Aya ».
    String? label,
    /// Version de la Bible ou recueil de cantiques, sous la référence.
    String? source,
  }) async {
    final locale = _locale(context);
    // Le logo doit être décodé avant la capture, sinon la première image
    // partagée l'aurait en blanc.
    try {
      await precacheImage(const AssetImage('assets/icons/app_icon.png'), context);
    } catch (_) {}
    if (!context.mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final boundaryKey = GlobalKey();

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        // Rendered fully off-screen (not just transparent) so it never
        // flashes on screen, but still gets a real layout/paint pass. Its
        // size is fixed so a short screen cannot squeeze the card.
        left: -10000,
        top: 0,
        width: VerseShareCard.width,
        height: VerseShareCard.height,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: boundaryKey,
            child: VerseShareCard(
              reference: reference,
              text: text,
              label: label ?? AppStrings.t('share_label_verse', locale),
              source: source,
              locale: locale,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    try {
      // Wait a couple of frames to guarantee layout/paint has completed
      // before capture.
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final file = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'verset_partage.png',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          text: '${text.trim()}\n— $reference\n\n'
              '${AppStrings.tf('share_message', locale, {
                'url': AppShareService.playStoreUrl(AppShareService.fallbackPackageId),
              })}',
          // iOS (notably iOS 26+) requires a non-zero anchor rect for the
          // share sheet popover, even on iPhone where it's visually unused.
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );
    } finally {
      entry.remove();
    }
  }
}
