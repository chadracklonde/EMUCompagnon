import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_cards.dart';
import 'package:provider/provider.dart';
import '../../../core/models/dictionary_entry.dart';
import '../../../core/settings/app_settings.dart';
import '../../../shared/bible_reference_parser.dart';
import '../../../shared/bible_book_abbreviations.dart';
import '../../../shared/widgets/linked_verse_text.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../bible/screens/chapter_screen.dart';

class DictionaryDetailScreen extends StatelessWidget {
  final DictionaryEntry entry;
  final bool showBackButton;
  const DictionaryDetailScreen({super.key, required this.entry, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    final lineHeightScale = context.watch<AppSettings>().lineHeightScale;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        title: const Text('Dictionnaire biblique'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: ReadingWidthConstraint(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.term,
                style: TextStyle(
                  fontSize: 26,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),
              // Bible references mentioned inline in the definition (e.g.
              // "Genèse 12") become tappable links straight to that passage.
              LinkedVerseText(
                entry.definition,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.6 * lineHeightScale,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (entry.relatedReferences.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionTitle('Références bibliques'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.relatedReferences
                      .map((ref) => ActionChip(
                            avatar: Icon(
                              Icons.menu_book_outlined,
                              size: 16,
                              color: AppPalette.of(context).accent,
                            ),
                            label: Text(ref),
                            onPressed: () => _openReference(context, ref),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openReference(BuildContext context, String ref) {
    // Each chip is a single, self-contained reference (not free-flowing
    // prose), so try the dedicated chip parser first — it understands
    // both full book names and the French abbreviations ("Gn", "Hé"...)
    // used by the imported dictionary content. Fall back to the
    // general-purpose parser just in case.
    final fallbackMatches = BibleReferenceParser.findAll(ref);
    final m = parseChipReference(ref) ?? (fallbackMatches.isNotEmpty ? fallbackMatches.first : null);
    if (m == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChapterScreen(
          book: m.book,
          chapter: m.chapter,
          highlightVerse: m.verse,
        ),
      ),
    );
  }
}
