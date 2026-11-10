import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/sacraments_data.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';

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
      body: ReadingWidthConstraint(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const InfoNote(SacramentsData.introNote),
            const SizedBox(height: 20),
            AppRowGroup(rows: [
              for (final s in SacramentsData.items)
                AppRow(
                  icon: _iconFor(s.icon),
                  title: s.name,
                  subtitle: s.subtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SacramentDetailScreen(sacrament: s)),
                  ),
                ),
            ]),
          ],
        ),
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
      appBar: AppBar(title: const Text('Sacrements et rites')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: ReadingWidthConstraint(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppPalette.of(context).accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconFor(sacrament.icon), color: AppPalette.of(context).accent),
              ),
              const SizedBox(height: 14),
              Text(
                sacrament.name,
                style: TextStyle(
                  fontSize: 26,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sacrament.subtitle,
                style: TextStyle(fontSize: 15, color: AppPalette.of(context).muted),
              ),
              const SizedBox(height: 20),
              Text(
                sacrament.description,
                style: TextStyle(
                  fontSize: 16.5,
                  height: 1.6 * lineHeightScale,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
