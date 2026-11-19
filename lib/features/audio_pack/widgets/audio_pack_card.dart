import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../hymn_audio_pack.dart';

/// Le bloc « Écouter sans connexion » : état du pack d'enregistrements, et les
/// boutons pour le télécharger, l'arrêter, le reprendre ou le supprimer.
/// Utilisé dans les Réglages, sur l'écran de proposition au démarrage et sur
/// l'écran ouvert depuis le lecteur.
class AudioPackCard extends StatefulWidget {
  /// Le service ; l'instance de l'application par défaut (injectable en test).
  final HymnAudioPack? pack;

  /// Sans titre ni description (quand l'écran qui l'héberge les affiche déjà).
  final bool bare;
  const AudioPackCard({super.key, this.pack, this.bare = false});

  @override
  State<AudioPackCard> createState() => _AudioPackCardState();
}

class _AudioPackCardState extends State<AudioPackCard> {
  HymnAudioPack get _service => widget.pack ?? HymnAudioPack.instance;

  @override
  void initState() {
    super.initState();
    _service.ensureLoaded().catchError((_) {});
  }

  bool get bare => widget.bare;

  @override
  Widget build(BuildContext context) {
    final service = _service;
    final locale = context.watch<AppSettings>().locale;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => _content(context, service, locale),
    );
  }

  Widget _content(BuildContext context, HymnAudioPack pack, String locale) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    String t(String key, [Map<String, Object> v = const {}]) => AppStrings.tf(key, locale, v);
    final total = formatMegabytes(pack.totalBytes, locale);
    final remaining = formatMegabytes(pack.totalBytes - pack.installedBytes, locale);

    Widget status;
    Widget? action;
    if (!pack.supported) {
      status = Text(t('audio_pack_unsupported'), style: TextStyle(color: palette.muted));
    } else if (!pack.loaded) {
      status = const SizedBox(height: 4, child: LinearProgressIndicator());
    } else if (pack.downloading) {
      status = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: pack.total == 0 ? null : pack.installedBytes / pack.totalBytes,
              backgroundColor: palette.border,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('audio_pack_progress', {'done': pack.installed, 'total': pack.total}),
            style: TextStyle(color: palette.muted, fontSize: 13.5),
          ),
        ],
      );
      action = _button(context, t('audio_pack_cancel'), pack.cancel, filled: false);
    } else if (pack.complete) {
      status = Row(children: [
        Icon(Icons.check_circle, color: palette.accent, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            t('audio_pack_done', {'n': pack.total, 'size': total}),
            style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
          ),
        ),
      ]);
      action = _button(context, t('audio_pack_remove'), pack.remove, filled: false);
    } else {
      final partial = pack.installed > 0;
      final failed = pack.state == AudioPackState.error;
      status = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            partial
                ? t('audio_pack_partial', {
                    'done': pack.installed,
                    'total': pack.total,
                    'size': formatMegabytes(pack.installedBytes, locale),
                  })
                : t('audio_pack_none'),
            style: TextStyle(color: palette.muted, fontSize: 13.5),
          ),
          if (failed) ...[
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.error_outline, size: 18, color: scheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t('audio_pack_error'),
                    style: TextStyle(color: scheme.error, fontSize: 13.5)),
              ),
            ]),
          ],
        ],
      );
      action = _button(
        context,
        failed
            ? t('audio_pack_retry')
            : partial
                ? t('audio_pack_resume', {'size': remaining})
                : t('audio_pack_download', {'size': total}),
        pack.start,
        filled: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!bare) ...[
          Text(t('audio_pack_title'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurface)),
          const SizedBox(height: 6),
          Text(
            t('audio_pack_desc', {'n': pack.total, 'size': total}),
            style: TextStyle(color: palette.muted, height: 1.45),
          ),
          const SizedBox(height: 14),
        ],
        status,
        if (action != null) ...[const SizedBox(height: 14), action],
        if (pack.supported && !pack.complete) ...[
          const SizedBox(height: 10),
          Text(t('audio_pack_wifi'), style: TextStyle(color: palette.muted, fontSize: 12.5)),
        ],
      ],
    );
  }

  Widget _button(BuildContext context, String label, VoidCallback onPressed, {required bool filled}) {
    final child = Text(label, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700));
    return SizedBox(
      height: 52,
      child: filled
          ? FilledButton(onPressed: onPressed, child: child)
          : OutlinedButton(onPressed: onPressed, child: child),
    );
  }
}
