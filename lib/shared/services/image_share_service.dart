import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/verse_share_card.dart';

/// Renders a [VerseShareCard] off-screen, captures it as a PNG, writes it
/// to a temp file, and opens the native share sheet.
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
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/verset_partage.png');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '$text\n— $reference\n\nEMU Compagnon',
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
