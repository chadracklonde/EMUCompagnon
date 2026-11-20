import '../../../core/models/bible_version.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/models/verse.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import 'bible_note.dart';
import 'note_text.dart';
import 'notes_mode.dart';

/// Le choix du mode de lecture, sous la barre du haut : Texte, Étude, Notes.
/// Les boutons font 48 px de haut, faciles à toucher d'une main.
class NotesModeBar extends StatelessWidget {
  final NotesMode mode;
  final ValueChanged<NotesMode> onChanged;
  const NotesModeBar({super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Semantics(
        label: context.tr('bn_modes'),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<NotesMode>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
              visualDensity: VisualDensity.standard,
            ),
            segments: [
              ButtonSegment(
                  value: NotesMode.text, label: Text(context.tr('bn_text'))),
              ButtonSegment(
                  value: NotesMode.study, label: Text(context.tr('bn_study'))),
              ButtonSegment(
                  value: NotesMode.notes, label: Text(context.tr('bn_notes'))),
            ],
            selected: {mode},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ),
      ),
    );
  }
}

TextStyle _noteStyle(BuildContext context) {
  final settings = context.watch<AppSettings>();
  return TextStyle(
    fontSize: 16,
    height: 1.6 * settings.lineHeightScale,
    color: Theme.of(context).colorScheme.onSurface,
  );
}

/// Le crédit d'une version qui en demande un (la Bible annotée) : une ligne
/// sous le texte, qui ouvre le site de l'auteur de la numérisation.
class VersionCredit extends StatelessWidget {
  final BibleVersion version;
  const VersionCredit({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    final line = version.creditLine;
    final url = version.creditUrl;
    if (line == null) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Semantics(
        link: url != null,
        hint: context.tr('bn_credit_open'),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: url == null
              ? null
              : () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12.5, height: 1.45, color: palette.muted),
                children: [
                  TextSpan(text: '$line — '),
                  if (url != null)
                    TextSpan(
                      text: url.replaceFirst('https://', ''),
                      style: TextStyle(
                          color: palette.accent,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline),
                    ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mode Étude : le début de la note sous son dernier verset. « Lire la
/// suite » la déplie, « Réduire » la referme.
class StudyNoteCard extends StatefulWidget {
  final String html;
  const StudyNoteCard({super.key, required this.html});

  @override
  State<StudyNoteCard> createState() => _StudyNoteCardState();
}

class _StudyNoteCardState extends State<StudyNoteCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final blocks = parseNote(widget.html);
    final long = blocks.length > 1 ||
        (blocks.isNotEmpty && blocks.first.plain.length > 160);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 4, 0, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 4),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: palette.accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NoteText(
            widget.html,
            style: _noteStyle(context),
            firstBlockOnly: !_open,
            maxLines: _open ? null : 3,
          ),
          if (long)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48), padding: EdgeInsets.zero),
                onPressed: () => setState(() => _open = !_open),
                child: Text(context.tr(_open ? 'bn_less' : 'bn_more'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Mode Notes : les notes lues comme un commentaire. Chaque entrée rappelle
/// ses versets en citation courte et renvoie au texte d'un seul toucher.
class BibleNotesView extends StatelessWidget {
  final ChapterNotes notes;
  final List<Verse> verses;

  /// « Jean 3.14-15 » pour une plage de versets.
  final String Function(String range) titleFor;
  final ValueChanged<int> onShowVerse;
  final ScrollController? controller;
  final Widget? footer;

  const BibleNotesView({
    super.key,
    required this.notes,
    required this.verses,
    required this.titleFor,
    required this.onShowVerse,
    this.controller,
    this.footer,
  });

  String _quote(NoteGroup g) {
    final text = verses
        .where((v) => g.covers(v.verse))
        .map((v) => '${v.verse} ${v.text}')
        .join(' ');
    return text.length <= 110 ? text : '${text.substring(0, 110).trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final style = _noteStyle(context);
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        for (final intro in notes.intros)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('bn_intro').toUpperCase(),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: palette.accent)),
                const SizedBox(height: 6),
                NoteText(intro, style: style),
              ],
            ),
          ),
        for (final g in notes.groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: palette.border, height: 20),
                Text(titleFor(g.range),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palette.accent)),
                const SizedBox(height: 4),
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                      border: Border(
                          left: BorderSide(color: palette.border, width: 3))),
                  child: Text(_quote(g),
                      style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: palette.muted,
                          height: 1.4)),
                ),
                NoteText(g.html, style: style),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: EdgeInsets.zero),
                    onPressed: () => onShowVerse(g.start),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: Text(context.tr('bn_see_verse')),
                  ),
                ),
              ],
            ),
          ),
        if (footer != null) footer!,
      ],
    );
  }
}
