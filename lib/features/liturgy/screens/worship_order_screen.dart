import '../../../shared/widgets/keep_awake.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/worship_order_data.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../church_texts/data/book_of_worship_data.dart';
import '../../church_texts/screens/church_text_screen.dart';
import '../../church_texts/screens/church_texts_screen.dart';
import '../../church_texts/widgets/church_text_links.dart';

class WorshipOrderScreen extends StatelessWidget {
  const WorshipOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lineHeightScale = context.watch<AppSettings>().lineHeightScale;
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final steps = WorshipOrderData.steps;

    return KeepAwake(child: Scaffold(
      appBar: AppBar(title: const Text('Ordre du culte')),
      body: ReadingWidthConstraint(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            InfoNote(WorshipOrderData.introNote, lineHeightScale: lineHeightScale),
            const SizedBox(height: 16),
            AppCard(
              child: AppRow(
                icon: churchTextIcon(BookOfWorshipData.basicPattern.icon),
                title: BookOfWorshipData.basicPattern.title,
                subtitle: 'Les quatre mouvements du culte, selon le Livre de culte',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ChurchTextScreen(text: BookOfWorshipData.basicPattern)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < steps.length; i++)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Numbered badge with a line running down to the next step.
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.accentSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: palette.accent,
                            ),
                          ),
                        ),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: palette.border,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              steps[i].title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              steps[i].description,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5 * lineHeightScale,
                                color: scheme.onSurface,
                              ),
                            ),
                            ChurchTextLinks(textIds: steps[i].textIds),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const SectionTitle('Textes du Livre de culte'),
            AppRowGroup(rows: [
              for (final text in BookOfWorshipData.all)
                AppRow(
                  icon: churchTextIcon(text.icon),
                  title: text.title,
                  subtitle: text.subtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChurchTextScreen(text: text)),
                  ),
                ),
            ]),
          ],
        ),
      ),
    ));
  }
}
