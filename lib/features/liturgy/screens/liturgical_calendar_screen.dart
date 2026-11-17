import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../models/liturgical_period.dart';
import '../services/liturgical_calendar_service.dart';
import '../widgets/season_card.dart';
import '../services/church_calendar.dart';
import 'church_day_screen.dart';
import 'liturgical_period_detail_screen.dart';

class LiturgicalCalendarScreen extends StatefulWidget {
  const LiturgicalCalendarScreen({super.key});

  @override
  State<LiturgicalCalendarScreen> createState() => _LiturgicalCalendarScreenState();
}

class _LiturgicalCalendarScreenState extends State<LiturgicalCalendarScreen> {
  final DateTime _today = ChurchCalendar.dayOnly(DateTime.now());
  late int _startYear = ChurchCalendar.churchYearStartFor(_today);
  bool _specials = true;

  int get _currentYear => ChurchCalendar.churchYearStartFor(_today);

  /// The Easter algorithm is valid for the Gregorian calendar.
  static const _firstYear = 1583;
  static const _lastYear = 2999;

  void _go(int delta) => setState(() => _startYear = (_startYear + delta).clamp(_firstYear, _lastYear));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _today,
      firstDate: DateTime(_firstYear),
      lastDate: DateTime(_lastYear, 12, 31),
      helpText: 'Chercher une date',
      cancelText: 'Annuler',
      confirmText: 'Voir',
    );
    if (picked == null || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _DateSheet(
        date: picked,
        onOpen: (day) {
          Navigator.of(context).pop();
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChurchDayScreen(day: day)));
        },
        onShowYear: () {
          Navigator.of(context).pop();
          setState(() => _startYear = ChurchCalendar.churchYearStartFor(picked));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isCurrentYear = _startYear == _currentYear;
    final periods = LiturgicalCalendarService.periodsForChurchYear(_startYear);
    final (current, _) = LiturgicalCalendarService.currentSeason(_today);
    final holyDayToday = isCurrentYear ? LiturgicalCalendarService.holyDayOn(_today, periods) : null;
    final seasons = ChurchCalendar.seasons(_startYear);
    final days = ChurchCalendar.churchYear(_startYear, specials: _specials);

    Widget dayRow(ChurchDay day) {
      final isToday = day.date == _today;
      return InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChurchDayScreen(day: day))),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 46,
                  child: Column(
                    children: [
                      Text('${day.date.day}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface)),
                      Text(formatShortDate(day.date).split(' ')[1],
                          style: TextStyle(fontSize: 11.5, color: palette.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day.name,
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: day.isSpecial ? FontWeight.w500 : FontWeight.w600,
                              color: scheme.onSurface)),
                      const SizedBox(height: 2),
                      Text(
                        '${frenchLongDate(day.date).split(' ').first}'
                        '${day.isSpecial ? ' · dimanche spécial' : ''} · ${day.color.name}',
                        style: TextStyle(fontSize: 12.5, color: palette.muted),
                      ),
                    ],
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(99)),
                    child: Text("Aujourd'hui",
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: palette.accent)),
                  ),
                ],
                const SizedBox(width: 8),
                ChurchColorDot(color: day.color, size: 18),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier liturgique'),
        actions: [
          IconButton(
            tooltip: 'Chercher une date',
            icon: const Icon(Icons.edit_calendar_outlined),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (holyDayToday != null) ...[
              _HolyDayBanner(instance: holyDayToday, onTap: () => _openDetail(context, holyDayToday)),
              const SizedBox(height: 12),
            ],
            if (isCurrentYear) ...[
              SeasonCard(instance: current, onTap: () => _openDetail(context, current)),
              const SizedBox(height: 20),
            ],
            // Year navigation: any year is computed, nothing is stored per year.
            Row(
              children: [
                IconButton(
                  tooltip: 'Année précédente',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _startYear > _firstYear ? () => _go(-1) : null,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Année chrétienne $_startYear–${_startYear + 1}',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: scheme.onSurface),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Année lectionnaire ${ChurchCalendar.lectionaryYear(_startYear)}',
                        style: TextStyle(fontSize: 13, color: palette.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Année suivante',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _startYear < _lastYear ? () => _go(1) : null,
                ),
              ],
            ),
            if (!isCurrentYear)
              Align(
                child: TextButton.icon(
                  icon: const Icon(Icons.today_outlined, size: 18),
                  label: const Text("Revenir à aujourd'hui"),
                  onPressed: () => setState(() => _startYear = _currentYear),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              "Les saisons et les jours sont calculés d'après la date de Pâques : ils sont justes pour n'importe quelle année.",
              style: TextStyle(fontSize: 13.5, height: 1.45, color: palette.muted),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < periods.length; i++) ...[
                    if (i > 0) Divider(indent: 58, color: palette.border),
                    _PeriodRow(
                      instance: periods[i],
                      isCurrent: isCurrentYear && periods[i] == current,
                      onTap: () => _openDetail(context, periods[i]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Jours et dimanches'),
            AppCard(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                title: const Text('Dimanches spéciaux de l\'Église',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Communion mondiale, UMCOR, paix avec la justice… (Discipline ¶ 262 à 265)',
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
                value: _specials,
                onChanged: (v) => setState(() => _specials = v),
              ),
            ),
            const SizedBox(height: 16),
            for (final season in seasons)
              if (days.any((d) => d.seasonId == season.id)) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Row(
                    children: [
                      ChurchColorDot(color: season.color, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(season.name,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: scheme.onSurface)),
                      ),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    children: [
                      for (final entry in days.where((d) => d.seasonId == season.id).toList().asMap().entries) ...[
                        if (entry.key > 0) Divider(height: 1, indent: 70, color: palette.border),
                        dayRow(entry.value),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, LiturgicalPeriodInstance instance) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LiturgicalPeriodDetailScreen(instance: instance)),
    );
  }
}

/// What a chosen date is in the Christian year.
class _DateSheet extends StatelessWidget {
  final DateTime date;
  final void Function(ChurchDay day) onOpen;
  final VoidCallback onShowYear;
  const _DateSheet({required this.date, required this.onOpen, required this.onShowYear});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final days = ChurchCalendar.daysOn(date);
    final season = ChurchCalendar.seasonOn(date);
    final color = ChurchCalendar.colorOn(date);
    final next = ChurchCalendar.nextSunday(date);
    final start = ChurchCalendar.churchYearStartFor(date);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(frenchLongDate(date),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: scheme.onSurface)),
            const SizedBox(height: 10),
            Row(children: [
              ChurchColorDot(color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${season.name} · ${color.name}', style: TextStyle(fontSize: 15, color: scheme.onSurface)),
              ),
            ]),
            const SizedBox(height: 4),
            Text('Année chrétienne $start–${start + 1} · lectionnaire ${ChurchCalendar.lectionaryYear(start)}',
                style: TextStyle(fontSize: 13, color: palette.muted)),
            const SizedBox(height: 14),
            if (days.isEmpty)
              Text(
                'Jour ordinaire de la saison.'
                '${next != null && next.date != ChurchCalendar.dayOnly(date) ? ' Prochain dimanche : ${next.name} (${frenchLongDate(next.date)}).' : ''}',
                style: TextStyle(fontSize: 15, height: 1.45, color: scheme.onSurface),
              )
            else
              for (final day in days)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(day.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: day.isSpecial ? const Text('Dimanche spécial') : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onOpen(day),
                ),
            const SizedBox(height: 6),
            TextButton.icon(
              icon: const Icon(Icons.calendar_view_month_outlined, size: 18),
              label: const Text('Voir toute cette année chrétienne'),
              onPressed: onShowYear,
            ),
          ],
        ),
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
