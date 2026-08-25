import 'package:flutter/material.dart';
import '../../core/models/bible_version.dart';

/// Shows the list of Bible versions (available or "coming soon") and
/// returns the chosen version code, or null if dismissed.
Future<String?> showVersionPicker(BuildContext context, {required String current}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('Version de la Bible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...BibleVersions.all.map((v) => ListTile(
                  enabled: v.available,
                  leading: Icon(
                    v.code == current ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: v.available
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  title: Text(v.name),
                  subtitle: Text(v.available ? v.language : (v.note ?? 'Bientôt disponible')),
                  trailing: v.available ? null : const Chip(label: Text('Bientôt', style: TextStyle(fontSize: 11))),
                  onTap: v.available ? () => Navigator.pop(context, v.code) : null,
                )),
          ],
        ),
      ),
    ),
  );
}
