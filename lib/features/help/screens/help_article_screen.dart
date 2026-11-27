import 'package:flutter/material.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../data/help_content.dart';
import 'help_shot_view.dart';

/// Un sujet de l'aide : une phrase d'introduction, des étapes numérotées et,
/// quand il y en a un, un bouton qui ouvre l'écran concerné.
class HelpArticleScreen extends StatelessWidget {
  final HelpArticle article;
  const HelpArticleScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final open = article.open;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(article.title.of(lang))),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(article.intro.of(lang),
                style: TextStyle(fontSize: 16, height: 1.5, color: palette.muted)),
            const SizedBox(height: 22),
            for (var i = 0; i < article.steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: '${i + 1}',
                      excludeSemantics: true,
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: palette.accent, shape: BoxShape.circle),
                        child: Text('${i + 1}',
                            style: TextStyle(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(article.steps[i].text.of(lang),
                                style: TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: scheme.onSurface)),
                            if (article.steps[i].shot != null)
                              HelpShotView(shot: article.steps[i].shot!),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (open != null) ...[
              const SizedBox(height: 6),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                icon: const Icon(Icons.open_in_new),
                label: Text(article.openLabel?.of(lang) ??
                    context.tr('help_open')),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => open())),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
