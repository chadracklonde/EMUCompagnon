import 'package:flutter/material.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/responsive/responsive.dart';
import '../../../shared/widgets/app_cards.dart';
import '../data/help_content.dart';
import 'help_article_screen.dart';

/// L'aide : une recherche, un premier sujet mis en avant, puis la liste des
/// sujets. Elle s'ouvre depuis l'onglet Plus.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _controller = TextEditingController();
  String _query = '';
  // Sur ordinateur : le sujet affiché à droite de la liste.
  HelpArticle _selected = HelpContent.articles.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(HelpArticle a) {
    if (Responsive.isWide(context)) {
      setState(() => _selected = a);
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => HelpArticleScreen(article: a)));
  }

  AppRow _row(HelpArticle a, String lang) => AppRow(
        icon: a.icon,
        title: a.title.of(lang),
        subtitle: a.subtitle.of(lang),
        onTap: () => _open(a),
      );

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final palette = AppPalette.of(context);
    final searching = _query.trim().isNotEmpty;
    final results = HelpContent.search(_query, lang);
    final featured = HelpContent.articles.first;
    final others = HelpContent.articles.skip(1).toList();

    final list = ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: context.tr('help_search'),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: context.tr('help_clear'),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: palette.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: palette.border),
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (searching) ...[
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(context.tr('help_none'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted)),
            )
          else
            AppRowGroup(rows: [for (final a in results) _row(a, lang)]),
        ] else ...[
          _Featured(article: featured, onTap: () => _open(featured)),
          const SizedBox(height: 24),
          SectionTitle(context.tr('help_topics')),
          AppRowGroup(rows: [for (final a in others) _row(a, lang)]),
        ],
      ],
    );

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(context.tr('help_title'))),
      body: Responsive.isWide(context)
          ? Row(
              children: [
                SizedBox(width: 380, child: list),
                VerticalDivider(width: 1, color: palette.border),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: HelpArticleBody(
                          key: ValueKey(_selected.id),
                          article: _selected,
                          showTitle: true),
                    ),
                  ),
                ),
              ],
            )
          : ReadingWidthConstraint(maxWidth: 640, child: list),
    );
  }
}

/// Le premier sujet, en grand : « Bien commencer ».
class _Featured extends StatelessWidget {
  final HelpArticle article;
  final VoidCallback onTap;
  const _Featured({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    return Semantics(
      button: true,
      child: Material(
        color: AppPalette.hero,
        borderRadius: BorderRadius.circular(kCardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(article.icon, color: AppPalette.onHero, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(article.title.of(lang),
                          style: const TextStyle(
                              color: AppPalette.onHero,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(article.subtitle.of(lang),
                          style: const TextStyle(
                              color: AppPalette.onHeroMuted, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppPalette.onHero),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
