import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/settings/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(title: const Text('Affichage')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Thème',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('Système'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('Clair'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Sombre'),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) {
              settings.setThemeMode(selection.first);
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Taille du texte',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ajuste la taille des versets, cantiques et définitions.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 14)),
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
              const Text('A', style: TextStyle(fontSize: 26)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Interligne',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            "Espace vertical entre les lignes, utile pour distinguer "
            "plus clairement chaque verset.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          Row(
            children: [
              const Icon(Icons.format_line_spacing, size: 18),
              Expanded(
                child: Slider(
                  value: settings.lineHeightScale,
                  min: AppSettings.minLineHeightScale,
                  max: AppSettings.maxLineHeightScale,
                  divisions: 7,
                  label: '${(settings.lineHeightScale * 100).round()} %',
                  onChanged: (v) => settings.setLineHeightScale(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Live preview so the user sees the effect immediately.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '16 ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  TextSpan(
                    text: "Car Dieu a tant aimé le monde qu'il a donné son "
                        "Fils unique, afin que quiconque croit en lui ne "
                        "périsse point, mais qu'il ait la vie éternelle.",
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.5 * settings.lineHeightScale,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: const Text('Réinitialiser les réglages'),
              onPressed: () => settings.resetToDefaults(),
            ),
          ),
        ],
      ),
    );
  }
}
