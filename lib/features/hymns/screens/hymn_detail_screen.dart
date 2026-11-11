import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/hymn.dart';
import '../../../core/models/bookmark.dart';
import '../../../core/settings/app_settings.dart';
import '../../favorites/repository/bookmark_repository.dart';
import '../../notes/screens/notes_sheet.dart';
import '../../../shared/services/image_share_service.dart';
import '../../../shared/services/text_share_service.dart';
import '../../../shared/widgets/linked_verse_text.dart';
import '../../../shared/widgets/text_settings_popup.dart';
import '../utils/hymn_stanza_parser.dart';
import '../../../core/services/reading_history_service.dart';
import '../../../shared/widgets/hymn_audio_player.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../core/theme/app_theme.dart';
import '../../hymn_lists/widgets/list_dialogs.dart';

class HymnDetailScreen extends StatefulWidget {
  final Hymn hymn;
  /// False when embedded as the detail pane of a wide-screen master-detail
  /// layout (no back button needed there — there's nothing to pop back
  /// from within that pane).
  final bool showBackButton;

  /// Shown under the hymn — the previous / next bar when singing through a list.
  final Widget? bottomBar;
  const HymnDetailScreen({
    super.key,
    required this.hymn,
    this.showBackButton = true,
    this.bottomBar,
  });

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
      bottomNavigationBar: widget.bottomBar,
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        title: Text('N° ${hymn.number}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Taille du texte',
            onPressed: () => showTextSettingsPopup(context),
          ),
          if (!_loading)
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.star : Icons.star_outline,
                color: _isBookmarked ? AppPalette.of(context).accent : null,
              ),
              tooltip: _isBookmarked ? 'Retirer des favoris' : 'Ajouter aux favoris',
              onPressed: _toggle,
            ),
          // Less frequent actions, kept out of the bar so it stays readable.
          PopupMenuButton<String>(
            tooltip: 'Plus d\'actions',
            onSelected: (value) {
              switch (value) {
                case 'list':
                  showAddToListSheet(context, number: hymn.number, title: hymn.title);
                case 'notes':
                  showNotesSheet(
                    context,
                    type: BookmarkType.hymn,
                    refId: hymn.id,
                    label: '${hymn.number} — ${hymn.title}',
                  );
                case 'share_text':
                  TextShareService.share(
                    TextShareService.hymnText(
                      number: '${hymn.number}',
                      title: hymn.title,
                      stanzas: stanzas,
                    ),
                    subject: '${hymn.number} — ${hymn.title}',
                  );
                case 'share':
                  ImageShareService.shareVerse(
                    context,
                    reference: '${hymn.number} — ${hymn.title}',
                    text: stanzas.isNotEmpty ? stanzas.first.body : hymn.title,
                  );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'list',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.playlist_add),
                  title: Text('Ajouter à une liste'),
                ),
              ),
              PopupMenuItem(
                value: 'notes',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.sticky_note_2_outlined),
                  title: Text('Notes'),
                ),
              ),
              PopupMenuItem(
                value: 'share_text',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.share_outlined),
                  title: Text('Partager le texte'),
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.image_outlined),
                  title: Text('Partager comme image'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: ReadingWidthConstraint(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hymn.title,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (hymn.key != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppPalette.of(context).accentSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Tonalité : ${hymn.key}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.of(context).accent,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (hymn.audioUrl != null) HymnAudioPlayer(audioUrl: hymn.audioUrl!),
              ...stanzas.map((s) => _StanzaBlock(stanza: s, lineHeightScale: lineHeightScale)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A verse is plain text beside its number; the refrain is set apart in a
/// soft tinted block so singers find it at a glance.
class _StanzaBlock extends StatelessWidget {
  final HymnStanza stanza;
  final double lineHeightScale;
  const _StanzaBlock({required this.stanza, required this.lineHeightScale});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final body = LinkedVerseText(
      stanza.body,
      style: TextStyle(
        fontSize: 17.5,
        height: 1.6 * lineHeightScale,
        color: scheme.onSurface,
        fontStyle: stanza.isRefrain ? FontStyle.italic : FontStyle.normal,
      ),
    );

    if (stanza.isRefrain) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 22),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: palette.accentSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stanza.label.isNotEmpty) ...[
              Text(
                stanza.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: palette.accent,
                ),
              ),
              const SizedBox(height: 6),
            ],
            body,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stanza.label.isNotEmpty)
            SizedBox(
              width: 30,
              child: Padding(
                padding: EdgeInsets.only(top: 3 * lineHeightScale),
                child: Text(
                  stanza.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
