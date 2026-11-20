import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/models/bible_version.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/bible_book_names.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import 'bible_note.dart';
import 'bible_notes_repository.dart';
import 'note_text.dart';
import 'notes_widgets.dart';

/// Les introductions d'un livre. Un seul texte : il s'ouvre directement.
/// Plusieurs (le Pentateuque, Job, le Cantique…) : une liste à choisir.
class BookIntroScreen extends StatefulWidget {
  final String book;
  final String version;
  const BookIntroScreen({super.key, required this.book, required this.version});

  @override
  State<BookIntroScreen> createState() => _BookIntroScreenState();
}

class _BookIntroScreenState extends State<BookIntroScreen> {
  late final Future<List<BookIntro>> _intros =
      BibleNotesRepository.introsForBook(widget.version, widget.book);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookIntro>>(
      future: _intros,
      builder: (context, snap) {
        final intros = snap.data;
        if (intros == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.tr('bi_intro'))),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (intros.length == 1) {
          return IntroReaderScreen(
              intro: intros.first, version: widget.version, book: widget.book);
        }
        final palette = AppPalette.of(context);
        return Scaffold(
          appBar: AppBar(
              title: Text(
                  '${context.tr('bi_intro')} · ${context.bookName(widget.book, version: widget.version)}')),
          body: ReadingWidthConstraint(
            maxWidth: 640,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                for (final i in intros)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      minVerticalPadding: 14,
                      title: Text(i.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing:
                          Icon(Icons.chevron_right, color: palette.muted),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => IntroReaderScreen(
                              intro: i,
                              version: widget.version,
                              book: widget.book))),
                    ),
                  ),
                VersionCredit(version: BibleVersions.byCode(widget.version)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// La lecture d'une introduction, paragraphe par paragraphe (ces textes
/// atteignent parfois cent mille caractères : la liste ne construit que ce
/// qui est à l'écran).
class IntroReaderScreen extends StatelessWidget {
  final BookIntro intro;
  final String version;
  final String book;
  const IntroReaderScreen(
      {super.key, required this.intro, required this.version, required this.book});

  /// Coupe le texte après chaque paragraphe, titre ou liste.
  static List<String> chunks(String html) => [
        for (final c in html.split(RegExp(r'(?<=</p>)|(?<=</h>)|(?<=</ul>)')))
          if (c.trim().isNotEmpty) c,
      ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final parts = chunks(intro.html);
    final style = TextStyle(
      fontSize: 16,
      height: 1.6 * settings.lineHeightScale,
      color: Theme.of(context).colorScheme.onSurface,
    );
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.bookName(book, version: version)),
            Text(intro.title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: AppPalette.of(context).muted)),
          ],
        ),
      ),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          itemCount: parts.length + 1,
          itemBuilder: (context, i) {
            if (i == parts.length) {
              return VersionCredit(version: BibleVersions.byCode(version));
            }
            final heading = parts[i].trimLeft().startsWith('<h>');
            return Padding(
              padding: EdgeInsets.only(top: heading ? 14 : 0),
              child: NoteText(parts[i], style: style),
            );
          },
        ),
      ),
    );
  }
}

/// La ligne qui mène aux introductions d'un livre (liste des chapitres).
/// N'affiche rien quand le livre n'en a pas dans cette version.
class BookIntroEntry extends StatelessWidget {
  final String book;
  final String version;
  final EdgeInsets margin;
  const BookIntroEntry(
      {super.key,
      required this.book,
      required this.version,
      this.margin = const EdgeInsets.fromLTRB(20, 8, 20, 4)});

  @override
  Widget build(BuildContext context) {
    if (!BibleVersions.byCode(version).hasNotes) return const SizedBox.shrink();
    return FutureBuilder<List<BookIntro>>(
      future: BibleNotesRepository.introsForBook(version, book),
      builder: (context, snap) {
        final intros = snap.data;
        if (intros == null || intros.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: margin,
          child: Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              minVerticalPadding: 12,
              leading: Icon(Icons.menu_book_outlined,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(context.tr('bi_intro'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(context.tr('bi_intro_sub')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BookIntroScreen(book: book, version: version))),
            ),
          ),
        );
      },
    );
  }
}
