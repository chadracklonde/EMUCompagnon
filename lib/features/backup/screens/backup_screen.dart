import '../../../core/l10n/tr.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
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
  DateTime? _lastExport;

  @override
  void initState() {
    super.initState();
    _loadLastExport();
  }

  void _loadLastExport() {
    BackupService.lastExport().then((d) {
      if (mounted) setState(() => _lastExport = d);
    }).catchError((_) {});
  }

  String _lastExportLabel(BuildContext context) {
    final last = _lastExport;
    if (last == null) return context.tr('bk_never');
    final days = DateTime.now().difference(last).inDays;
    if (days <= 0) return context.tr('bk_today');
    if (days == 1) return context.tr('bk_yesterday');
    return context.trf('bk_days_ago', {'n': days});
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await _service.exportAndShare(context.lang);
      _loadLastExport();
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
          builder: (dialogContext) => AlertDialog(
            title: Text(dialogContext.tr('bk_done')),
            content: Text(
              dialogContext.trf('bk_done_body', {
                'b': summary.bookmarks,
                'n': summary.notes,
                'h': summary.highlights,
                'm': summary.memoryCards,
                'j': summary.journalEntries,
                'e': summary.examenEntries,
              }),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(dialogContext.tr('ok'))),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('bk_fail'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('bk_title'))),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            InfoNote(context.tr('bk_info')),
            const SizedBox(height: 12),
            InfoNote(context.tr('bk_warn')),
            const SizedBox(height: 16),
            Text(
              _lastExportLabel(context),
              style: TextStyle(fontSize: 14, color: AppPalette.of(context).muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.upload_outlined),
              label: Text(context.tr('bk_export')),
              onPressed: _busy ? null : _export,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.download_outlined),
              label: Text(context.tr('bk_import')),
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
