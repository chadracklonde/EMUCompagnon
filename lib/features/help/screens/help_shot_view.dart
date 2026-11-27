import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_theme.dart';
import '../data/help_content.dart';
import '../data/help_shots.dart';

/// Une capture d'écran de l'aide. On peut :
/// - toucher une zone entourée : une bulle l'explique et, quand c'est
///   possible, propose d'ouvrir l'écran réel ;
/// - l'agrandir (bouton en haut à gauche), puis zoomer à deux doigts.
class HelpShotView extends StatefulWidget {
  final HelpShot shot;
  const HelpShotView({super.key, required this.shot});

  @override
  State<HelpShotView> createState() => _HelpShotViewState();
}

class _Loaded {
  final HelpShotInfo info;
  final Uint8List bytes;
  const _Loaded(this.info, this.bytes);
}

class _HelpShotViewState extends State<HelpShotView> {
  Future<_Loaded?>? _future;
  String? _lang;
  String? _selected;
  final _bubbleKey = GlobalKey();

  /// Après un choix, fait défiler jusqu'à la bulle : sur une capture haute,
  /// elle est sous l'image, hors de l'écran.
  void _select(String key) {
    setState(() => _selected = key == _selected ? null : key);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _bubbleKey.currentContext;
      if (_selected != null && c != null && c.mounted) {
        Scrollable.ensureVisible(c,
            duration: const Duration(milliseconds: 250), alignment: 0.6);
      }
    });
  }

  Future<_Loaded?> _fetch(String lang) async {
    final info = await HelpShots.info(lang, widget.shot.id);
    final bytes = await HelpShots.image(lang, widget.shot.id);
    if (info == null || bytes == null) return null;
    return _Loaded(info, bytes);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    if (_lang != lang) {
      _lang = lang;
      _selected = null;
      _future = _fetch(lang);
    }
    return FutureBuilder<_Loaded?>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();
        return _content(context, data, lang);
      },
    );
  }

  Widget _content(BuildContext context, _Loaded data, String lang) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    HelpHotspot? chosen;
    for (final h in widget.shot.hotspots) {
      if (h.key == _selected) chosen = h;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            image: true,
            label: widget.shot.caption.of(lang),
            child: Container(
              decoration: BoxDecoration(
                color: palette.field,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              padding: const EdgeInsets.all(8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: AspectRatio(
                    aspectRatio: data.info.ratio,
                    child: LayoutBuilder(builder: (context, box) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(data.bytes,
                                  fit: BoxFit.fill, gaplessPlayback: true),
                            ),
                          ),
                          for (final h in widget.shot.hotspots)
                            if (data.info.rects[h.key] case final r?)
                              Positioned(
                                left: r[0] * box.maxWidth - 3,
                                top: r[1] * box.maxHeight - 3,
                                width: r[2] * box.maxWidth + 6,
                                height: r[3] * box.maxHeight + 6,
                                child: _HotspotButton(
                                  label: h.title.of(lang),
                                  selected: h.key == _selected,
                                  onTap: () => _select(h.key),
                                ),
                              ),
                          Positioned(
                            left: -2,
                            top: -2,
                            child: Material(
                              color: palette.card,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: IconButton(
                                tooltip: context.tr('help_zoom'),
                                icon: const Icon(Icons.zoom_out_map, size: 20),
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => HelpShotViewer(
                                            bytes: data.bytes,
                                            title: widget.shot.caption.of(lang)))),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          if (widget.shot.hotspots.isNotEmpty && chosen == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(context.tr('help_tap_hint'),
                  style: TextStyle(fontSize: 12.5, color: palette.muted)),
            ),
          if (chosen != null)
            Container(
              key: _bubbleKey,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.accent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(chosen.title.of(lang),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: scheme.onSurface)),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: context.tr('help_close'),
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(() => _selected = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(chosen.body.of(lang),
                      style: TextStyle(
                          fontSize: 14, height: 1.45, color: palette.muted)),
                  if (chosen.open != null) ...[
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46)),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => chosen!.open!())),
                      child: Text(context.tr('help_open_screen')),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HotspotButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _HotspotButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = AppPalette.of(context).accent;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: selected ? accent.withValues(alpha: 0.18) : null,
            border: Border.all(
                color: selected ? accent : accent.withValues(alpha: 0.75),
                width: selected ? 3 : 2),
          ),
        ),
      ),
    );
  }
}

/// La capture en grand, qu'on peut zoomer et déplacer.
class HelpShotViewer extends StatelessWidget {
  final Uint8List bytes;
  final String title;
  const HelpShotViewer({super.key, required this.bytes, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 14)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: context.tr('help_close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
      ),
    );
  }
}
