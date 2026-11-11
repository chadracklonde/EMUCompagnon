import 'package:flutter/material.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../data/church_texts_data.dart';
import '../models/church_text.dart';
import 'church_text_screen.dart';

IconData churchTextIcon(ChurchTextIcon icon) {
  switch (icon) {
    case ChurchTextIcon.prayer:
      return Icons.volunteer_activism_outlined;
    case ChurchTextIcon.creed:
      return Icons.public_outlined;
    case ChurchTextIcon.litany:
      return Icons.record_voice_over_outlined;
    case ChurchTextIcon.articles:
      return Icons.menu_book_outlined;
    case ChurchTextIcon.confession:
      return Icons.verified_outlined;
    case ChurchTextIcon.rules:
      return Icons.rule_outlined;
    case ChurchTextIcon.vows:
      return Icons.how_to_reg_outlined;
    case ChurchTextIcon.mission:
      return Icons.explore_outlined;
  }
}

/// "Prières et textes": the prayers, creeds and doctrinal texts of the
/// Church, grouped by use.
class ChurchTextsScreen extends StatelessWidget {
  const ChurchTextsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prières et textes')),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            for (final group in ChurchTextsData.groups) ...[
              SectionTitle(group.title),
              AppRowGroup(rows: [
                for (final text in group.texts)
                  AppRow(
                    icon: churchTextIcon(text.icon),
                    title: text.title,
                    subtitle: text.subtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ChurchTextScreen(text: text)),
                    ),
                  ),
              ]),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
