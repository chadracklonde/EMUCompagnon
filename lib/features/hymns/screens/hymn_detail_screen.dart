import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/hymn.dart';
import '../../../core/models/bookmark.dart';
import '../../../core/settings/app_settings.dart';
import '../../favorites/repository/bookmark_repository.dart';
import '../../notes/screens/notes_sheet.dart';
import '../../../shared/services/image_share_service.dart';
import '../../../shared/widgets/linked_verse_text.dart';
import '../../../shared/widgets/text_settings_popup.dart';
import '../utils/hymn_stanza_parser.dart';
import '../../../core/services/reading_history_service.dart';
import '../../../shared/widgets/hymn_audio_player.dart';

class HymnDetailScreen extends StatefulWidget {
  final Hymn hymn;
  const HymnDetailScreen({super.key, required this.hymn});

  @override
  State<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends State<HymnDetailScreen> {
  final _bookmarkRepo = BookmarkRepository();
  bool _isBookmarked = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ReadingHistoryService.saveLastHymnRead(widget.hymn.number, widget.hymn.title);
    _load();
  }

  Future<void> _load() async {
    final bookmarked = await _bookmarkRepo.isBookmarked(
      BookmarkType.hymn,
      widget.hymn.id,
    );
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
        _loading = false;
      });
    }
  }

  Future<void> _toggle() async {
    final nowBookmarked = await _bookmarkRepo.toggle(
      BookmarkType.hymn,
      widget.hymn.id,
      note: '${widget.hymn.number} — ${widget.hymn.title}',
    );
    setState(() => _isBookmarked = nowBookmarked);
  }

  @override
  Widget build(BuildContext context) {
    final hymn = widget.hymn;
    final lineHeightScale = context.watch<AppSettings>().lineHeightScale;
    final stanzas = HymnStanzaParser.parse(hymn.lyrics);

    return Scaffold(
      appBar: AppBar(
        title: Text('N° ${hymn.number}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Taille du texte',
            onPressed: () => showTextSettingsPopup(context),
          ),
          IconButton(
            icon: const Icon(Icons.image_outlined),
            tooltip: 'Partager comme image',
            onPressed: () => ImageShareService.shareVerse(
              context,
              reference: '${hymn.number} — ${hymn.title}',
              text: stanzas.isNotEmpty ? stanzas.first.body : hymn.title,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sticky_note_2_outlined),
            tooltip: 'Notes',
            onPressed: () => showNotesSheet(
              context,
              type: BookmarkType.hymn,
              refId: hymn.id,
              label: '${hymn.number} — ${hymn.title}',
            ),
          ),
          if (!_loading)
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.star : Icons.star_border,
                color: _isBookmarked ? Colors.amber : null,
              ),
              tooltip: _isBookmarked ? 'Retirer des favoris' : 'Ajouter aux favoris',
              onPressed: _toggle,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                hymn.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            if (hymn.key != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Tonalité : ${hymn.key}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (hymn.audioUrl != null) HymnAudioPlayer(audioUrl: hymn.audioUrl!),
            ...stanzas.map((s) => _StanzaBlock(stanza: s, lineHeightScale: lineHeightScale)),
          ],
        ),
      ),
    );
  }
}

class _StanzaBlock extends StatelessWidget {
  final HymnStanza stanza;
  final double lineHeightScale;
  const _StanzaBlock({required this.stanza, required this.lineHeightScale});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: stanza.isRefrain
            ? scheme.primaryContainer.withValues(alpha: 0.5)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: stanza.isRefrain
            ? Border.all(color: scheme.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stanza.label.isNotEmpty) ...[
            Text(
              stanza.isRefrain ? stanza.label.toUpperCase() : stanza.label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: stanza.isRefrain ? 12 : 14,
                letterSpacing: stanza.isRefrain ? 1 : 0,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 6),
          ],
          LinkedVerseText(
            stanza.body,
            style: TextStyle(fontSize: 17, height: 1.5 * lineHeightScale),
          ),
        ],
      ),
    );
  }
}
