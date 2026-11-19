import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../services/content_update_service.dart';

class ContentUpdateScreen extends StatefulWidget {
  const ContentUpdateScreen({super.key});

  @override
  State<ContentUpdateScreen> createState() => _ContentUpdateScreenState();
}

class _ContentUpdateScreenState extends State<ContentUpdateScreen> {
  int _localVersion = 1;
  DateTime? _lastChecked;
  bool _checking = false;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await ContentUpdateService.getLocalVersion();
    final last = await ContentUpdateService.getLastChecked();
    if (mounted) setState(() {
      _localVersion = v;
      _lastChecked = last;
    });
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _resultMessage = null;
    });
    final result = await ContentUpdateService.checkAndApplyUpdate();
    await _load();
    if (mounted) {
      setState(() {
        _checking = false;
        _resultMessage = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;

    Widget infoLine(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: palette.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 14.5, color: scheme.onSurface)),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Mises à jour du contenu')),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const InfoNote(
              'Permet de recevoir des corrections ou des ajouts au contenu '
              '(Bible, cantiques, dictionnaire) sans attendre une mise à jour '
              "complète de l'application. Vos favoris, notes et surlignages ne "
              'sont jamais affectés.',
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                children: [
                  infoLine(Icons.info_outline, 'Version du contenu actuel', '$_localVersion'),
                  if (_lastChecked != null) ...[
                    Divider(indent: 16, color: palette.border),
                    infoLine(
                      Icons.access_time,
                      'Dernière vérification',
                      '${_lastChecked!.day}/${_lastChecked!.month}/${_lastChecked!.year}',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: _checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_sync_outlined),
              label: Text(_checking ? 'Vérification…' : 'Vérifier les mises à jour'),
              onPressed: _checking ? null : _check,
            ),
            if (_resultMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _resultMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.accent, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
