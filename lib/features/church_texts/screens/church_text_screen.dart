import '../../../shared/widgets/keep_awake.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/services/text_share_service.dart';
import '../../../shared/widgets/text_settings_popup.dart';
import '../../../shared/widgets/linked_verse_text.dart';
import '../models/church_text.dart';
import '../services/church_text_prefs.dart';
import 'church_texts_screen.dart';

/// Reading page of one prayer or text.
class ChurchTextScreen extends StatefulWidget {
  final ChurchText text;

  /// Heading to open at (a search result); otherwise reading resumes
  /// where it stopped.
  final int? initialHeading;
  const ChurchTextScreen({super.key, required this.text, this.initialHeading});

  @override
  State<ChurchTextScreen> createState() => _ChurchTextScreenState();
}

class _ChurchTextScreenState extends State<ChurchTextScreen> {
  /// One key per heading, so the table of contents can scroll to it.
  late final List<GlobalKey> _headingKeys = [
    for (final _ in widget.text.headings) GlobalKey(),
  ];

  /// Texts with only a few sections do not need a table of contents.
  bool get _hasContents => _headingKeys.length >= 4;

  final _scroll = ScrollController();
  bool _pinned = false;
  bool _showToTop = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    ChurchTextPrefs.isPinned(widget.text.id).then((p) {
      if (mounted) setState(() => _pinned = p);
    });
    final heading = widget.initialHeading;
    if (heading != null && heading < _headingKeys.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _headingKeys[heading].currentContext;
        if (target != null && target.mounted) Scrollable.ensureVisible(target);
      });
      return;
    }
    // Long texts reopen where reading stopped.
    ChurchTextPrefs.position(widget.text.id).then((offset) {
      if (offset <= 0 || !mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
      });
    });
  }

  void _onScroll() {
    final show = _scroll.offset > 600;
    if (show != _showToTop) setState(() => _showToTop = show);
  }

  @override
  void dispose() {
    if (_scroll.hasClients) {
      ChurchTextPrefs.savePosition(widget.text.id, _scroll.offset);
    }
    _scroll.dispose();
    super.dispose();
  }

  /// The text in the language of the app (Swahili when a version exists).
  ChurchText _localized(BuildContext context) =>
      widget.text.localized(context.read<AppSettings>().locale);

  void _share() =>
      TextShareService.share(_localized(context).toPlainText(), subject: _localized(context).title);

  Future<void> _togglePin() async {
    final pinned = await ChurchTextPrefs.toggle(widget.text.id);
    if (!mounted) return;
    setState(() => _pinned = pinned);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(pinned ? "Épinglé sur l'accueil" : "Retiré de l'accueil"),
      ));
  }

  /// Long press on a passage: share or copy only its section (one
  /// article), not the whole text.
  Future<void> _openSectionActions(int blockIndex) async {
    final text = _localized(context);
    final title = text.sectionTitleOf(blockIndex) ?? text.title;
    final content = text.headings.isEmpty
        ? text.toPlainText()
        : text.sectionPlainText(blockIndex);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Partager ce passage'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                TextShareService.share(content, subject: title);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copier ce passage'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await Clipboard.setData(ClipboardData(text: content));
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Passage copié')));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openContents() async {
    final headings = _localized(context).headings;
    final index = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (context, controller) => ListView.builder(
          controller: controller,
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: headings.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(headings[i]),
            onTap: () => Navigator.of(context).pop(i),
          ),
        ),
      ),
    );
    if (index == null || !mounted) return;
    final target = _headingKeys[index].currentContext;
    if (target == null || !target.mounted) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _localized(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lineHeight = context.watch<AppSettings>().lineHeightScale;

    var headingIndex = 0;
    final body = <Widget>[];
    for (var i = 0; i < text.blocks.length; i++) {
      final block = text.blocks[i];
      final key = block.kind == TextBlockKind.heading ? _headingKeys[headingIndex++] : null;
      // The speaker is named once per turn, not on every line.
      final previous = i == 0 ? null : text.blocks[i - 1].kind;
      body.add(_Block(
        key: key,
        block: block,
        lineHeight: lineHeight,
        showSpeaker: previous != block.kind,
        onLongPress: () => _openSectionActions(i),
      ));
    }

    return KeepAwake(child: Scaffold(
      appBar: AppBar(
        actions: [
          if (_hasContents)
            IconButton(
              tooltip: 'Sommaire',
              icon: const Icon(Icons.format_list_bulleted),
              onPressed: _openContents,
            ),
          IconButton(
            tooltip: _pinned ? "Retirer de l'accueil" : "Épingler sur l'accueil",
            icon: Icon(
              _pinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _pinned ? palette.accent : null,
            ),
            onPressed: _togglePin,
          ),
          PopupMenuButton<String>(
            tooltip: "Plus d'actions",
            onSelected: (value) {
              switch (value) {
                case 'size':
                  showTextSettingsPopup(context);
                case 'share':
                  _share();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'size',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.text_fields),
                  title: Text('Taille du texte'),
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.share_outlined),
                  title: Text('Partager tout le texte'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: _showToTop
          ? FloatingActionButton.small(
              tooltip: 'Revenir en haut',
              onPressed: () => _scroll.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
              child: const Icon(Icons.arrow_upward),
            )
          : null,
      body: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        child: ReadingWidthConstraint(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(churchTextIcon(text.icon), color: palette.accent),
              ),
              const SizedBox(height: 14),
              Text(
                text.title,
                style: TextStyle(
                  fontSize: 26,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(text.subtitle, style: TextStyle(fontSize: 15, color: palette.muted)),
              const SizedBox(height: 12),
              ...body,
              const SizedBox(height: 28),
              Divider(color: palette.border),
              const SizedBox(height: 12),
              LinkedVerseText(
                text.source,
                style: TextStyle(fontSize: 13, height: 1.4, color: palette.muted),
              ),
              if (text.sourceUrl != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text("Voir l'original (en anglais)"),
                    onPressed: () => launchUrl(Uri.parse(text.sourceUrl!), mode: LaunchMode.externalApplication),
                  ),
                ),
              if (text.headings.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Appui long sur un passage pour le partager ou le copier seul.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: palette.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    ));
  }
}

class _Block extends StatelessWidget {
  final TextBlock block;
  final double lineHeight;

  /// Whether a responsive line names who says it.
  final bool showSpeaker;
  final VoidCallback onLongPress;
  const _Block({
    super.key,
    required this.block,
    required this.lineHeight,
    required this.showSpeaker,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      onLongPressHint: 'partager ou copier ce passage',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: onLongPress,
        child: SizedBox(width: double.infinity, child: _content(context)),
      ),
    );
  }

  Widget _speaker(BuildContext context, String name) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          name.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppPalette.of(context).muted,
          ),
        ),
      );

  Widget _content(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final bodyStyle = TextStyle(
      fontSize: 16.5,
      height: 1.6 * lineHeight,
      color: scheme.onSurface,
    );

    switch (block.kind) {
      case TextBlockKind.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Semantics(
            header: true,
            child: Text(
              block.text,
              style: TextStyle(
                fontSize: 17.5,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
          ),
        );
      case TextBlockKind.paragraph:
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: LinkedVerseText(block.text, style: bodyStyle),
        );
      case TextBlockKind.leader:
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSpeaker) _speaker(context, 'Officiant'),
              LinkedVerseText(block.text, style: bodyStyle),
            ],
          ),
        );
      case TextBlockKind.people:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSpeaker) _speaker(context, 'Assemblée'),
              LinkedVerseText(
                block.text,
                style: bodyStyle.copyWith(fontWeight: FontWeight.w700, color: palette.accent),
              ),
            ],
          ),
        );
      case TextBlockKind.item:
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 10 * lineHeight, right: 12, left: 2),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle),
                ),
              ),
              Expanded(child: LinkedVerseText(block.text, style: bodyStyle)),
            ],
          ),
        );
      case TextBlockKind.note:
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            block.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5 * lineHeight,
              fontStyle: FontStyle.italic,
              color: palette.muted,
            ),
          ),
        );
    }
  }
}
