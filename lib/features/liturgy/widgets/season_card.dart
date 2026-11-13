import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_cards.dart';
import '../models/liturgical_period.dart';

const _shortMonths = [
  '', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String formatShortDate(DateTime d) => '${d.day} ${_shortMonths[d.month]} ${d.year}';

/// Small filled shape in a period's liturgical colour: a rounded square
/// for a season, a circle for a holy day. The hairline border keeps white
/// and very light colours visible on a white card.
class LiturgicalSwatch extends StatelessWidget {
  final LiturgicalPeriod period;
  final double size;
  const LiturgicalSwatch({super.key, required this.period, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final isHolyDay = period.type == LiturgicalPeriodType.holyDay;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(period.colorHex),
        shape: isHolyDay ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isHolyDay ? null : BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppPalette.of(context).border),
      ),
    );
  }
}

/// "Aujourd'hui" card for the current season: a neutral card with the
/// liturgical colour as a side band, instead of a fully coloured block.
class SeasonCard extends StatelessWidget {
  final LiturgicalPeriodInstance instance;
  final VoidCallback onTap;
  const SeasonCard({super.key, required this.instance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final period = instance.period;

    return AppCard(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 8, color: Color(period.colorHex)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AUJOURD'HUI",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      period.name,
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      period.summary,
                      style: TextStyle(fontSize: 14, height: 1.4, color: scheme.onSurface),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${formatShortDate(instance.start)} — ${formatShortDate(instance.end)}'
                      ' · Couleur : ${period.colorName}',
                      style: TextStyle(fontSize: 12.5, color: palette.muted),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right, color: palette.muted, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
