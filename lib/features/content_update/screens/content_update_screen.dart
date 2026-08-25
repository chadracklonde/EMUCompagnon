import 'package:flutter/material.dart';
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mises à jour du contenu')),
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
              "Permet de recevoir des corrections ou des ajouts au "
              "contenu (Bible, cantiques, dictionnaire) sans attendre une "
              "mise à jour complète de l'app sur le store. Tes favoris, "
              "notes et surlignages ne sont jamais affectés.",
              style: TextStyle(fontSize: 13.5, height: 1.5, color: scheme.onSecondaryContainer),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version du contenu actuel'),
            trailing: Text('$_localVersion', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (_lastChecked != null)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Dernière vérification'),
              trailing: Text(
                '${_lastChecked!.day}/${_lastChecked!.month}/${_lastChecked!.year}',
              ),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: _checking
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_sync_outlined),
            label: Text(_checking ? 'Vérification…' : 'Vérifier les mises à jour'),
            onPressed: _checking ? null : _check,
          ),
          if (_resultMessage != null) ...[
            const SizedBox(height: 16),
            Text(_resultMessage!, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
