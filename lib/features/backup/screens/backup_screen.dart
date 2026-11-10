import 'package:flutter/material.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _service = BackupService();
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await _service.exportAndShare();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final summary = await _service.pickFileAndImport();
      if (summary != null && mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Importation terminée'),
            content: Text(
              '${summary.bookmarks} favori(s), ${summary.notes} note(s), '
              '${summary.highlights} surlignage(s), '
              '${summary.memoryCards} verset(s) à mémoriser, '
              '${summary.journalEntries} page(s) de journal et '
              '${summary.examenEntries} examen(s) du soir importé(s).\n\n'
              'Votre progression (plan de lecture, série de jours, quiz, défis) '
              'a été fusionnée sans rien diminuer. Les éléments déjà présents '
              'n\'ont pas été dupliqués.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'importation : fichier invalide')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sauvegarde de mes données')),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const InfoNote(
              'Vos favoris, notes, surlignages, versets à mémoriser, journal '
              'de prière, examens du soir et votre progression ne sont '
              'enregistrés que sur cet appareil. Exportez-les régulièrement '
              'pour ne rien perdre en cas de changement de téléphone ou de '
              'réinstallation — aucun compte requis, aucune donnée '
              'envoyée à un serveur.',
            ),
            const SizedBox(height: 12),
            const InfoNote(
              'Attention : le fichier exporté contient votre journal personnel. '
              'Ne le partagez qu’avec des personnes de confiance.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Exporter mes données'),
              onPressed: _busy ? null : _export,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.download_outlined),
              label: const Text('Importer une sauvegarde'),
              onPressed: _busy ? null : _import,
            ),
            if (_busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
