import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/linked_verse_text.dart';
import '../models/liturgical_period.dart';
import '../widgets/season_card.dart';

class LiturgicalPeriodDetailScreen extends StatelessWidget {
  final LiturgicalPeriodInstance instance;
  const LiturgicalPeriodDetailScreen({super.key, required this.instance});

  static const _months = [
    '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  String _fmt(DateTime d) => '${d.day} ${_months[d.month]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final period = instance.period;
    final isHolyDay = period.type == LiturgicalPeriodType.holyDay;
    final lineHeightScale = context.watch<AppSettings>().lineHeightScale;
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(isHolyDay ? 'Jour saint' : 'Saison liturgique')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: ReadingWidthConstraint(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The liturgical colour, as a band rather than a full header.
              Container(
                width: 56,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(period.colorHex),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: palette.border),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                period.name,
                style: TextStyle(
                  fontSize: 26,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isHolyDay
                    ? _fmt(instance.start)
                    : '${_fmt(instance.start)} → ${_fmt(instance.end)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LiturgicalSwatch(period: period, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'Couleur : ${period.colorName}',
                      style: TextStyle(fontSize: 13, color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                period.summary,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),
              LinkedVerseText(
                period.description,
                style: TextStyle(
                  fontSize: 16.5,
                  height: 1.6 * lineHeightScale,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
