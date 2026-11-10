import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../models/liturgical_period.dart';
import '../services/liturgical_calendar_service.dart';
import '../widgets/season_card.dart';
import 'liturgical_period_detail_screen.dart';

class LiturgicalCalendarScreen extends StatelessWidget {
  const LiturgicalCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final (current, all) = LiturgicalCalendarService.currentSeason(today);
    final holyDayToday = LiturgicalCalendarService.holyDayOn(today, all);
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendrier liturgique')),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (holyDayToday != null) ...[
              _HolyDayBanner(
                instance: holyDayToday,
                onTap: () => _openDetail(context, holyDayToday),
              ),
              const SizedBox(height: 12),
            ],
            SeasonCard(instance: current, onTap: () => _openDetail(context, current)),
            const SizedBox(height: 24),
            const SectionTitle("L'année chrétienne"),
            Text(
              "Six saisons et quatre jours saints rythment l'année chrétienne, "
              'chacun associé à une couleur liturgique.',
              style: TextStyle(fontSize: 13.5, height: 1.45, color: palette.muted),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < all.length; i++) ...[
                    if (i > 0) Divider(indent: 58, color: palette.border),
                    _PeriodRow(
                      instance: all[i],
                      isCurrent: all[i] == current,
                      onTap: () => _openDetail(context, all[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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

class _PeriodRow extends StatelessWidget {
  final LiturgicalPeriodInstance instance;
  final bool isCurrent;
  final VoidCallback onTap;
  const _PeriodRow({required this.instance, required this.isCurrent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final period = instance.period;
    final isHolyDay = period.type == LiturgicalPeriodType.holyDay;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              LiturgicalSwatch(period: period),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      period.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isHolyDay
                          ? formatShortDate(instance.start)
                          : '${formatShortDate(instance.start)} — ${formatShortDate(instance.end)}',
                      style: TextStyle(fontSize: 12.5, color: palette.muted),
                    ),
                  ],
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'En cours',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: palette.accent,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: palette.muted, size: 22),
            ],
          ),
        ),
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
    final palette = AppPalette.of(context);
    return Material(
      color: palette.accentSoft,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              LiturgicalSwatch(period: instance.period, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "C'est aujourd'hui : ${instance.period.name}",
                  style: TextStyle(fontWeight: FontWeight.w700, color: palette.accent),
                ),
              ),
              Icon(Icons.chevron_right, color: palette.accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
