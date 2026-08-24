import 'package:flutter/material.dart';
import 'liturgical_calendar_screen.dart';
import 'worship_order_screen.dart';
import 'sacraments_screen.dart';
import '../services/liturgical_calendar_service.dart';

class LiturgyScreen extends StatelessWidget {
  const LiturgyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final (current, _) = LiturgicalCalendarService.currentSeason();
    final color = Color(current.period.colorHex);

    return Scaffold(
      appBar: AppBar(title: const Text('Liturgie')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HubCard(
            icon: Icons.calendar_month,
            iconColor: color,
            title: 'Calendrier liturgique',
            subtitle: 'Saison du jour : ${current.period.name}',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LiturgicalCalendarScreen()),
            ),
          ),
          _HubCard(
            icon: Icons.checklist_rtl,
            iconColor: Theme.of(context).colorScheme.primary,
            title: 'Ordre du culte',
            subtitle: 'Déroulement habituel d\'un service dominical',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorshipOrderScreen()),
            ),
          ),
          _HubCard(
            icon: Icons.water_drop_outlined,
            iconColor: Theme.of(context).colorScheme.primary,
            title: 'Sacrements et rites',
            subtitle: 'Baptême, Sainte-Cène, mariage, funérailles…',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SacramentsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: iconColor.withValues(alpha: 0.15),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
