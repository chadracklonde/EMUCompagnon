import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/church_texts_data.dart';
import '../screens/church_text_screen.dart';
import '../screens/church_texts_screen.dart';

/// Links to the texts of [textIds] (ids of [ChurchTextsData]), shown under a
/// step of the service or a rite. Unknown ids are left out.
class ChurchTextLinks extends StatelessWidget {
  final List<String> textIds;
  const ChurchTextLinks({super.key, required this.textIds});

  @override
  Widget build(BuildContext context) {
    final texts = [
      for (final id in textIds)
        if (ChurchTextsData.byId(id) != null) ChurchTextsData.byId(id)!,
    ];
    if (texts.isEmpty) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final text in texts)
            ActionChip(
              avatar: Icon(churchTextIcon(text.icon), size: 18, color: palette.accent),
              label: Text(text.title),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChurchTextScreen(text: text)),
              ),
            ),
        ],
      ),
    );
  }
}
