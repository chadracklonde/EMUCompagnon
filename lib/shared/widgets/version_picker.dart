import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/settings/app_settings.dart';
import '../../core/models/bible_version.dart';

/// Shows the list of Bible versions (available or "coming soon") and
/// returns the chosen version code, or null if dismissed. The title and
/// labels follow the language chosen in the settings.
Future<String?> showVersionPicker(BuildContext context, {required String current}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final locale = sheetContext.read<AppSettings>().locale;
      String t(String key) => AppStrings.t(key, locale);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  t('bible_version'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ...BibleVersions.all.map((v) => ListTile(
                    enabled: v.available,
                    leading: Icon(
                      v.code == current ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: v.available
                          ? Theme.of(sheetContext).colorScheme.primary
                          : Theme.of(sheetContext).colorScheme.outline,
                    ),
                    title: Text(v.name),
                    subtitle: Text(v.available
                        ? (v.note == null ? v.language : '${v.language} · ${v.note}')
                        : (v.note ?? 'Bientôt disponible')),
                    trailing: v.available
                        ? null
                        : Chip(label: Text(t('soon'), style: const TextStyle(fontSize: 11))),
                    onTap: v.available ? () => Navigator.pop(sheetContext, v.code) : null,
                  )),
            ],
          ),
        ),
      );
    },
  );
}
