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

/// Lower-case, no accents: "Bénédiction" matches "benediction".
String foldForSearch(String text) {
  const accents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'œ': 'oe',
    '’': "'",
  };
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    buffer.write(accents[char] ?? char);
  }
  return buffer.toString();
}

/// The texts whose title or subtitle contain every word of [query].
List<ChurchText> searchChurchTexts(String query) {
  final words = foldForSearch(query)
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return const [];
  return [
    for (final text in ChurchTextsData.all)
      if (words.every(
          (w) => foldForSearch('${text.title} ${text.subtitle}').contains(w)))
        text,
  ];
}

/// "Prières et textes": the prayers, creeds and doctrinal texts of the
/// Church, grouped by use, with a search box at the top.
class ChurchTextsScreen extends StatefulWidget {
  const ChurchTextsScreen({super.key});

  @override
  State<ChurchTextsScreen> createState() => _ChurchTextsScreenState();
}

class _ChurchTextsScreenState extends State<ChurchTextsScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  AppRow _row(BuildContext context, ChurchText text) => AppRow(
        icon: churchTextIcon(text.icon),
        title: text.title,
        subtitle: text.subtitle,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChurchTextScreen(text: text)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    final found = searching ? searchChurchTexts(_query) : const <ChurchText>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Prières et textes')),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Chercher une prière ou un service',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searching
                    ? IconButton(
                        tooltip: 'Effacer',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
            if (searching) ...[
              if (found.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('Aucun texte ne correspond.')),
                )
              else
                AppRowGroup(
                    rows: [for (final text in found) _row(context, text)]),
            ] else
              for (final group in ChurchTextsData.groups) ...[
                SectionTitle(group.title),
                AppRowGroup(rows: [
                  for (final text in group.texts) _row(context, text)
                ]),
                const SizedBox(height: 24),
              ],
          ],
        ),
      ),
    );
  }
}
