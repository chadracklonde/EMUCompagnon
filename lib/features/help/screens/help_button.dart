import 'package:flutter/material.dart';

import '../../../core/l10n/tr.dart';
import '../data/help_content.dart';
import 'help_article_screen.dart';

/// Le « ? » des écrans qui méritent une explication : il ouvre l'article
/// d'aide correspondant. Sans article de ce nom, il ne s'affiche pas.
class HelpButton extends StatelessWidget {
  final String articleId;
  const HelpButton(this.articleId, {super.key});

  @override
  Widget build(BuildContext context) {
    final article = HelpContent.byId(articleId);
    if (article == null) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: context.tr('help_title'),
      onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HelpArticleScreen(article: article))),
    );
  }
}
