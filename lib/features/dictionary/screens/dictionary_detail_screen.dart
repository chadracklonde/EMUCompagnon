import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/dictionary_entry.dart';
import '../../../core/settings/app_settings.dart';
import '../../../shared/bible_reference_parser.dart';
import '../../../shared/widgets/linked_verse_text.dart';
import '../../bible/screens/chapter_screen.dart';

class DictionaryDetailScreen extends StatelessWidget {
  final DictionaryEntry entry;
  const DictionaryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final lineHeightScale = context.watch<AppSettings>().lineHeightScale;

    return Scaffold(
      appBar: AppBar(title: Text(entry.term)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bible references mentioned inline in the definition (e.g.
            // "Genèse 12") become tappable links straight to that passage.
            LinkedVerseText(
              entry.definition,
              style: TextStyle(fontSize: 17, height: 1.6 * lineHeightScale),
            ),
            if (entry.relatedReferences.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Références bibliques',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.relatedReferences
                    .map((ref) => ActionChip(
                          label: Text(ref),
                          onPressed: () => _openReference(context, ref),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openReference(BuildContext context, String ref) {
    final matches = BibleReferenceParser.findAll(ref);
    if (matches.isEmpty) return;
    final m = matches.first;
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
