import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../services/liturgical_calendar_service.dart';
import '../widgets/season_card.dart';
import 'liturgical_calendar_screen.dart';
import 'liturgical_period_detail_screen.dart';
import 'sacraments_screen.dart';
import 'worship_order_screen.dart';

class LiturgyScreen extends StatelessWidget {
  const LiturgyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final (current, _) = LiturgicalCalendarService.currentSeason();
    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('nav_liturgy', context.watch<AppSettings>().locale)),
      ),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            SeasonCard(
              instance: current,
              onTap: () => open(LiturgicalPeriodDetailScreen(instance: current)),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Explorer'),
            AppRowGroup(rows: [
              AppRow(
                icon: Icons.calendar_month_outlined,
                title: 'Calendrier liturgique',
                subtitle: "Les saisons et jours saints de l'année",
                onTap: () => open(const LiturgicalCalendarScreen()),
              ),
              AppRow(
                icon: Icons.checklist_rtl,
                title: 'Ordre du culte',
                subtitle: "Déroulement habituel d'un service dominical",
                onTap: () => open(const WorshipOrderScreen()),
              ),
              AppRow(
                icon: Icons.water_drop_outlined,
                title: 'Sacrements et rites',
                subtitle: 'Baptême, Sainte-Cène, mariage, funérailles…',
                onTap: () => open(const SacramentsScreen()),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
