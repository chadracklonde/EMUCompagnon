import '../../../core/l10n/tr.dart';
import 'package:flutter/material.dart';
import '../../worship/screens/worship_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../church_texts/screens/church_texts_screen.dart';
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
            const SizedBox(height: 12),
            AppCard(
              child: AppRow(
                icon: Icons.church_outlined,
                title: context.tr('lg_worship'),
                subtitle: context.tr('lg_worship_sub'),
                onTap: () => open(const WorshipScreen()),
              ),
            ),
            const SizedBox(height: 24),
            SectionTitle(context.tr('lg_explore')),
            AppRowGroup(rows: [
              AppRow(
                icon: Icons.calendar_month_outlined,
                title: context.tr('lg_cal'),
                subtitle: context.tr('lg_cal_sub'),
                onTap: () => open(const LiturgicalCalendarScreen()),
              ),
              AppRow(
                icon: Icons.checklist_rtl,
                title: context.tr('lg_order'),
                subtitle: context.tr('lg_order_sub'),
                onTap: () => open(const WorshipOrderScreen()),
              ),
              AppRow(
                icon: Icons.water_drop_outlined,
                title: context.tr('lg_sacr'),
                subtitle: context.tr('lg_sacr_sub'),
                onTap: () => open(const SacramentsScreen()),
              ),
              AppRow(
                icon: Icons.auto_stories_outlined,
                title: context.tr('ctl_title'),
                subtitle: context.tr('lg_texts_sub'),
                onTap: () => open(const ChurchTextsScreen()),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
