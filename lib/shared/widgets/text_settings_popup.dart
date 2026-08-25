import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/settings/app_settings.dart';

/// Compact bottom sheet with text-size and line-height sliders, for quick
/// in-context adjustment while reading (Bible, Cantiques). Changes apply
/// immediately and are the same persisted preference as the full
/// Settings screen — this is just a faster entry point.
Future<void> showTextSettingsPopup(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _TextSettingsPopup(),
  );
}

class _TextSettingsPopup extends StatelessWidget {
  const _TextSettingsPopup();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.text_fields, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Taille du texte', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 13)),
              Expanded(
                child: Slider(
                  value: settings.textScale,
                  min: AppSettings.minTextScale,
                  max: AppSettings.maxTextScale,
                  divisions: 8,
                  label: '${(settings.textScale * 100).round()} %',
                  onChanged: (v) => settings.setTextScale(v),
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.format_line_spacing, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Interligne', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: settings.lineHeightScale,
            min: AppSettings.minLineHeightScale,
            max: AppSettings.maxLineHeightScale,
            divisions: 7,
            label: '${(settings.lineHeightScale * 100).round()} %',
            onChanged: (v) => settings.setLineHeightScale(v),
          ),
        ],
      ),
    );
  }
}
