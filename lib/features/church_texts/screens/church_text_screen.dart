import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/services/text_share_service.dart';
import '../../../shared/widgets/text_settings_popup.dart';
import '../models/church_text.dart';
import 'church_texts_screen.dart';

/// Reading page of one prayer or text.
class ChurchTextScreen extends StatefulWidget {
  final ChurchText text;
  const ChurchTextScreen({super.key, required this.text});

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

  void _share() =>
      TextShareService.share(widget.text.toPlainText(), subject: widget.text.title);

  Future<void> _openContents() async {
    final headings = widget.text.headings;
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
    final text = widget.text;
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lineHeight = context.watch<AppSettings>().lineHeightScale;

    var headingIndex = 0;
    final body = <Widget>[];
    for (final block in text.blocks) {
      final key = block.kind == TextBlockKind.heading ? _headingKeys[headingIndex++] : null;
      body.add(_Block(key: key, block: block, lineHeight: lineHeight));
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_hasContents)
            IconButton(
              tooltip: 'Sommaire',
              icon: const Icon(Icons.format_list_bulleted),
              onPressed: _openContents,
            ),
          IconButton(
            tooltip: 'Taille du texte',
            icon: const Icon(Icons.text_fields),
            onPressed: () => showTextSettingsPopup(context),
          ),
          IconButton(
            tooltip: 'Partager',
            icon: const Icon(Icons.share_outlined),
            onPressed: _share,
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              Text(
                text.source,
                style: TextStyle(fontSize: 13, height: 1.4, color: palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final TextBlock block;
  final double lineHeight;
  const _Block({super.key, required this.block, required this.lineHeight});

  @override
  Widget build(BuildContext context) {
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
          child: Text(
            block.text,
            style: TextStyle(
              fontSize: 17.5,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: palette.accent,
            ),
          ),
        );
      case TextBlockKind.paragraph:
      case TextBlockKind.leader:
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(block.text, style: bodyStyle),
        );
      case TextBlockKind.people:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Text(
            block.text,
            style: bodyStyle.copyWith(fontWeight: FontWeight.w700, color: palette.accent),
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
              Expanded(child: Text(block.text, style: bodyStyle)),
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
