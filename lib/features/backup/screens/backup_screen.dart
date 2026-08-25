import 'package:flutter/material.dart';
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
              '${summary.bookmarks} favori(s), ${summary.notes} note(s) et '
              '${summary.highlights} surlignage(s) importé(s).\n\n'
              'Les éléments déjà présents n\'ont pas été dupliqués.',
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sauvegarde de mes données')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Tes favoris, notes et surlignages ne sont enregistrés que "
              "sur cet appareil. Exporte-les régulièrement pour ne rien "
              "perdre en cas de changement de téléphone ou de "
              "réinstallation — aucun compte requis, aucune donnée "
              "envoyée à un serveur : le fichier reste entre tes mains.",
              style: TextStyle(fontSize: 13.5, height: 1.5, color: scheme.onSecondaryContainer),
            ),
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
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
