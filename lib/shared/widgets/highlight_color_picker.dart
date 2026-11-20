import '../../core/l10n/tr.dart';
import 'package:flutter/material.dart';
import '../../core/models/highlight.dart';

/// Shows a small palette to pick a highlight color, or remove the
/// existing highlight. Returns the chosen hex color, or the literal
/// string 'remove', or null if dismissed without a choice.
Future<String?> showHighlightColorPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('hi_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: HighlightColors.palette.entries.map((entry) {
                final hex = HighlightColors.hexFor(entry.value);
                final isSelected = current == hex;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: context.trf('hi_in', {'color': context.tr('hi_c_${entry.key}')}),
                  excludeSemantics: true,
                  onTap: () => Navigator.pop(context, hex),
                  child: GestureDetector(
                  onTap: () => Navigator.pop(context, hex),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.black87, size: 22)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(context.tr('hi_c_${entry.key}'), style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                );
              }).toList(),
            ),
            if (current != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.close),
                label: Text(context.tr('hi_remove')),
                onPressed: () => Navigator.pop(context, 'remove'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
