import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/sacraments_data.dart';
import '../../../core/settings/app_settings.dart';

IconData _iconFor(IconRef ref) {
  switch (ref) {
    case IconRef.baptism:
      return Icons.water_drop_outlined;
    case IconRef.communion:
      return Icons.local_bar_outlined; // chalice-adjacent, closest Material icon
    case IconRef.confirmation:
      return Icons.how_to_reg_outlined;
    case IconRef.marriage:
      return Icons.favorite_border;
    case IconRef.funeral:
      return Icons.local_florist_outlined;
    case IconRef.ordination:
      return Icons.church_outlined;
  }
}

class SacramentsScreen extends StatelessWidget {
  const SacramentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sacrements et rites')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              SacramentsData.introNote,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...SacramentsData.items.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(_iconFor(s.icon), color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(s.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SacramentDetailScreen(sacrament: s)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class SacramentDetailScreen extends StatelessWidget {
  final SacramentInfo sacrament;
  const SacramentDetailScreen({super.key, required this.sacrament});

  @override
  Widget build(BuildContext context) {
    final lineHeightScale = context.watch<AppSettings>().lineHeightScale;
    return Scaffold(
      appBar: AppBar(title: Text(sacrament.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sacrament.subtitle,
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              sacrament.description,
              style: TextStyle(fontSize: 16, height: 1.6 * lineHeightScale),
            ),
          ],
        ),
      ),
    );
  }
}
