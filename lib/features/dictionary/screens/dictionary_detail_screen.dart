import 'package:flutter/material.dart';
import '../../../core/models/dictionary_entry.dart';

class DictionaryDetailScreen extends StatelessWidget {
  final DictionaryEntry entry;
  const DictionaryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(entry.term)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.definition,
              style: const TextStyle(fontSize: 17, height: 1.6),
            ),
            if (entry.relatedReferences.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Références bibliques',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.relatedReferences
                    .map((ref) => Chip(label: Text(ref)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
