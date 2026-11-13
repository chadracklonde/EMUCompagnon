import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';

/// Petite note de musique affichée à côté d'un cantique qui a un
/// enregistrement. À n'afficher que si `hymn.audioUrl != null`.
class HymnAudioMark extends StatelessWidget {
  const HymnAudioMark({super.key});

  @override
  Widget build(BuildContext context) {
    final label = AppStrings.t('audio_available', context.watch<AppSettings>().locale);
    return Tooltip(
      message: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          Icons.music_note_rounded,
          size: 20,
          color: AppPalette.of(context).accent,
          semanticLabel: label,
        ),
      ),
    );
  }
}
