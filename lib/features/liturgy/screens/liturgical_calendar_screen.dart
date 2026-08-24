import 'package:flutter/material.dart';
import '../models/liturgical_period.dart';
import '../services/liturgical_calendar_service.dart';
import 'liturgical_period_detail_screen.dart';

class LiturgicalCalendarScreen extends StatelessWidget {
  const LiturgicalCalendarScreen({super.key});

  static const _months = [
    '', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  String _fmt(DateTime d) => '${d.day} ${_months[d.month]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final (current, all) = LiturgicalCalendarService.currentSeason(today);
    final holyDayToday = LiturgicalCalendarService.holyDayOn(today, all);
    final color = Color(current.period.colorHex);
    final isLight = color.computeLuminance() > 0.6;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendrier liturgique')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (holyDayToday != null) ...[
            _HolyDayBanner(instance: holyDayToday, onTap: () => _openDetail(context, holyDayToday)),
            const SizedBox(height: 12),
          ],
          Material(
            color: color,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openDetail(context, current),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AUJOURD'HUI",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: (isLight ? Colors.black : Colors.white)
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current.period.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isLight ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      current.period.summary,
                      style: TextStyle(
                        fontSize: 14,
                        color: (isLight ? Colors.black : Colors.white)
                            .withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_fmt(current.start)} — ${_fmt(current.end)} · Couleur : ${current.period.colorName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: (isLight ? Colors.black : Colors.white)
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "L'année chrétienne",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            "Six saisons et quatre jours saints rythment l'année chrétienne, "
            "chacun associé à une couleur liturgique.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 12),
          ...all.map((instance) {
            final isCurrent = instance == current;
            final swatchColor = Color(instance.period.colorHex);
            final isHolyDay =
                instance.period.type == LiturgicalPeriodType.holyDay;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: isCurrent ? 2 : 0,
              color: isCurrent
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: isCurrent ? 0 : 0.5,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: swatchColor,
                    shape: isHolyDay ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isHolyDay
                        ? null
                        : BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                title: Text(
                  instance.period.name,
                  style: TextStyle(
                    fontWeight:
                        isHolyDay ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  isHolyDay
                      ? _fmt(instance.start)
                      : '${_fmt(instance.start)} — ${_fmt(instance.end)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => _openDetail(context, instance),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, LiturgicalPeriodInstance instance) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiturgicalPeriodDetailScreen(instance: instance),
      ),
    );
  }
}

class _HolyDayBanner extends StatelessWidget {
  final LiturgicalPeriodInstance instance;
  final VoidCallback onTap;
  const _HolyDayBanner({required this.instance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(instance.period.colorHex);
    final isLight = color.computeLuminance() > 0.6;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.celebration,
                color: isLight ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "C'est aujourd'hui : ${instance.period.name} !",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isLight ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
