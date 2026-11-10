import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_cards.dart';
import 'package:provider/provider.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/responsive/reading_width_constraint.dart';

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
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;

    Widget hint(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(text, style: TextStyle(fontSize: 13, height: 1.4, color: palette.muted)),
        );
    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            text,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: scheme.onSurface),
          ),
        );
    Widget group(List<Widget> children) => AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const SectionTitle('Apparence'),
            group([
              label("Langue de l'interface"),
              hint(
                'Traduit les menus et boutons. La Bible, les cantiques et le '
                'dictionnaire restent en français (traduction du contenu non '
                'encore disponible).',
              ),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'fr', label: Text('Français')),
                    ButtonSegment(value: 'sw', label: Text('Kiswahili')),
                  ],
                  selected: {settings.locale},
                  onSelectionChanged: (selection) => settings.setLocale(selection.first),
                ),
              ),
              const SizedBox(height: 22),
              label('Thème'),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('Système'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Clair'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Sombre'),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) => settings.setThemeMode(selection.first),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            const SectionTitle('Lecture'),
            group([
              label('Taille du texte'),
              hint('Ajuste la taille des versets, cantiques et définitions.'),
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
              const SizedBox(height: 14),
              label('Interligne'),
              hint('Espace vertical entre les lignes.'),
              Row(
                children: [
                  Icon(Icons.format_line_spacing, size: 18, color: palette.muted),
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
              const SizedBox(height: 14),
              label('Police'),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'system', label: Text('Système')),
                    ButtonSegment(value: 'serif', label: Text('Serif')),
                    ButtonSegment(value: 'sansSerif', label: Text('Sans-serif')),
                  ],
                  selected: {settings.fontFamily},
                  onSelectionChanged: (selection) => settings.setFontFamily(selection.first),
                ),
              ),
              const SizedBox(height: 18),
              // Live preview of the three settings above.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.field,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '16\u00A0\u00A0',
                        style: TextStyle(
                          fontFamily: settings.resolvedFontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: palette.accent,
                        ),
                      ),
                      TextSpan(
                        text: "Car Dieu a tant aimé le monde qu'il a donné son "
                            'Fils unique, afin que quiconque croit en lui ne '
                            "périsse point, mais qu'il ait la vie éternelle.",
                        style: TextStyle(
                          fontFamily: settings.resolvedFontFamily,
                          fontSize: 17.5,
                          height: 1.6 * settings.lineHeightScale,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            const SectionTitle('Rappel quotidien'),
            AppCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: const Text(
                      'Activer le rappel',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "Une notification à l'heure choisie pour vous inviter à votre lecture.",
                      style: TextStyle(fontSize: 13, color: palette.muted),
                    ),
                    value: settings.notificationsEnabled,
                    onChanged: (v) => _toggleNotifications(settings, v),
                  ),
                  if (settings.notificationsEnabled) ...[
                    Divider(indent: 16, color: palette.border),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: const Icon(Icons.access_time),
                      title: const Text('Heure du rappel', style: TextStyle(fontSize: 14.5)),
                      trailing: Text(
                        '${settings.notificationHour.toString().padLeft(2, '0')}:'
                        '${settings.notificationMinute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: palette.accent,
                        ),
                      ),
                      onTap: () => _pickTime(settings),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.restart_alt),
                label: const Text("Réinitialiser l'apparence et la lecture"),
                onPressed: () => settings.resetToDefaults(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
