import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../services/church_calendar.dart';

const _months = [
  '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];
const _weekdays = ['', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];

/// "dimanche 28 mars 2027".
String frenchLongDate(DateTime d) => '${_weekdays[d.weekday]} ${d.day} ${_months[d.month]} ${d.year}';

/// Colour swatch: a round dot with a hairline border so white stays visible.
class ChurchColorDot extends StatelessWidget {
  final LiturgicalColorInfo color;
  final double size;
  const ChurchColorDot({super.key, required this.color, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(color.hex),
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.of(context).border),
      ),
    );
  }
}

/// One day of the Christian year: what it is, its colour, how its date is fixed.
class ChurchDayScreen extends StatelessWidget {
  final ChurchDay day;
  const ChurchDayScreen({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lineHeight = context.watch<AppSettings>().lineHeightScale;
    final start = ChurchCalendar.churchYearStartFor(day.date);
    final season = ChurchCalendar.seasons(start).firstWhere((s) => s.id == day.seasonId,
        orElse: () => ChurchCalendar.seasonOn(day.date));

    Widget fact(String label, String value, {Widget? leading}) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(label, style: TextStyle(fontSize: 13.5, color: palette.muted)),
              ),
              if (leading != null) ...[leading, const SizedBox(width: 8)],
              Expanded(child: Text(value, style: TextStyle(fontSize: 15, color: scheme.onSurface))),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(day.isSpecial ? 'Dimanche spécial' : 'Jour liturgique')),
      body: ReadingWidthConstraint(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              day.name,
              style: TextStyle(
                fontSize: 24,
                height: 1.25,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(frenchLongDate(day.date), style: TextStyle(fontSize: 15.5, color: palette.muted)),
            const SizedBox(height: 8),
            fact('Saison', season.name),
            fact('Couleur', day.color.name, leading: ChurchColorDot(color: day.color)),
            fact('Année', 'Année chrétienne ${start}–${start + 1} · lectionnaire ${ChurchCalendar.lectionaryYear(start)}'),
            if (day.note != null) ...[
              const SizedBox(height: 22),
              Text(day.note!, style: TextStyle(fontSize: 16, height: 1.55 * lineHeight, color: scheme.onSurface)),
            ],
            if (day.rule != null) ...[
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(14)),
                child: Text(
                  'Date : ${day.rule}.\n\nLes dimanches spéciaux sont fixés par la Conférence générale ; '
                  "les conférences centrales ne sont pas tenues de tous les observer, et une église locale peut choisir "
                  'une autre date appropriée.',
                  style: TextStyle(fontSize: 13.5, height: 1.5, color: palette.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
