import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _toggleNotifications(AppSettings settings, bool enable) async {
    if (enable) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission de notification refusée')),
          );
        }
        return;
      }
      await NotificationService.scheduleDaily(
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
      );
    } else {
      await NotificationService.cancelDaily();
    }
    await settings.setNotificationsEnabled(enable);
  }

  Future<void> _pickTime(AppSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.notificationHour, minute: settings.notificationMinute),
    );
    if (picked == null) return;
    await settings.setNotificationTime(picked.hour, picked.minute);
    if (settings.notificationsEnabled) {
      await NotificationService.scheduleDaily(hour: picked.hour, minute: picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(title: const Text('Affichage')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Langue de l\'interface',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Traduit les menus et boutons. La Bible, les cantiques et le "
            "dictionnaire restent en français (traduction du contenu non "
            "encore disponible).",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'fr', label: Text('Français')),
              ButtonSegment(value: 'sw', label: Text('Kiswahili')),
            ],
            selected: {settings.locale},
            onSelectionChanged: (selection) => settings.setLocale(selection.first),
          ),
          const SizedBox(height: 32),
          Text(
            'Thème',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('Système')),
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Clair')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Sombre')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) => settings.setThemeMode(selection.first),
          ),
          const SizedBox(height: 32),
          Text(
            'Taille du texte',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Ajuste la taille des versets, cantiques et définitions.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Espace vertical entre les lignes, utile pour distinguer plus clairement chaque verset.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
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
          const SizedBox(height: 20),
          Text(
            'Police',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'system', label: Text('Système')),
              ButtonSegment(value: 'serif', label: Text('Serif')),
              ButtonSegment(value: 'sansSerif', label: Text('Sans-serif')),
            ],
            selected: {settings.fontFamily},
            onSelectionChanged: (selection) => settings.setFontFamily(selection.first),
          ),
          const SizedBox(height: 24),
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
                      fontFamily: settings.resolvedFontFamily,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  TextSpan(
                    text: "Car Dieu a tant aimé le monde qu'il a donné son "
                        "Fils unique, afin que quiconque croit en lui ne "
                        "périsse point, mais qu'il ait la vie éternelle.",
                    style: TextStyle(
                      fontFamily: settings.resolvedFontFamily,
                      fontSize: 17,
                      height: 1.5 * settings.lineHeightScale,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Rappel quotidien',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Reçois une notification à l'heure choisie pour t'inviter à ta lecture.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activer le rappel'),
            value: settings.notificationsEnabled,
            onChanged: (v) => _toggleNotifications(settings, v),
          ),
          if (settings.notificationsEnabled)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Heure du rappel'),
              trailing: Text(
                '${settings.notificationHour.toString().padLeft(2, '0')}:${settings.notificationMinute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _pickTime(settings),
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
