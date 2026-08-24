import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/liturgical_period.dart';
import '../../../core/settings/app_settings.dart';
import '../../../shared/widgets/linked_verse_text.dart';

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
    final color = Color(period.colorHex);
    final isLight = color.computeLuminance() > 0.6;
    final isHolyDay = period.type == LiturgicalPeriodType.holyDay;
    final lineHeightScale = context.watch<AppSettings>().lineHeightScale;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: color,
            foregroundColor: isLight ? Colors.black : Colors.white,
            pinned: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                period.name,
                style: TextStyle(
                  color: isLight ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(color: color),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Chip(
                      label: Text(isHolyDay ? 'Jour saint' : 'Saison'),
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      avatar: CircleAvatar(backgroundColor: color, radius: 8),
                      label: Text(period.colorName),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isHolyDay
                      ? _fmt(instance.start)
                      : '${_fmt(instance.start)} → ${_fmt(instance.end)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 20),
                LinkedVerseText(
                  period.description,
                  style: TextStyle(fontSize: 16, height: 1.6 * lineHeightScale),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
