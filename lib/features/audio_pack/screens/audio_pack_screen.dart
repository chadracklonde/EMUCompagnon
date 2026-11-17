import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../hymn_audio_pack.dart';
import '../widgets/audio_pack_card.dart';

/// Écran « Écouter sans connexion » ouvert depuis le lecteur quand l'audio ne
/// charge pas : même bloc que dans les Réglages.
class AudioPackScreen extends StatefulWidget {
  const AudioPackScreen({super.key});

  @override
  State<AudioPackScreen> createState() => _AudioPackScreenState();
}

class _AudioPackScreenState extends State<AudioPackScreen> {
  @override
  void initState() {
    super.initState();
    HymnAudioPack.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppSettings>().locale;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('audio_pack_settings', locale))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [AudioPackCard()],
      ),
    );
  }
}
