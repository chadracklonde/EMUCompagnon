import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/verse_share_card.dart';

/// Renders a [VerseShareCard] off-screen, captures it as a PNG, and opens
/// the native share sheet.
///
/// Deliberately platform-agnostic (no dart:io, no path_provider): the
/// captured PNG bytes are handed to share_plus directly via
/// `XFile.fromData`, which works in memory on every platform including
/// the web, where there is no real filesystem to write a temp file to.
class ImageShareService {
  static Future<void> shareVerse(
    BuildContext context, {
    required String reference,
    required String text,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final boundaryKey = GlobalKey();

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        // Rendered fully off-screen (not just transparent) so it never
        // flashes on screen, but still gets a real layout/paint pass.
        left: -10000,
        top: 0,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: boundaryKey,
            child: VerseShareCard(reference: reference, text: text),
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
          text: '$text\n— $reference\n\nÉMU Compagnon',
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
