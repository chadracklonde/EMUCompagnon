import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../settings/screens/settings_screen.dart';
import '../../backup/screens/backup_screen.dart';
import '../../content_update/screens/content_update_screen.dart';

/// "À propos" screen crediting the app's developer.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _phoneDisplay = '+243 814 479 335';
  static const _phoneRaw = '+243814479335';
  static const _email = 'chadracklonde@outlook.com';
  static const _whatsapp = 'https://wa.me/243814479335';
  static const _facebook = 'https://facebook.com/chadracklonde1';

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Material(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.tune, color: scheme.onSecondaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Affichage — thème, taille du texte, interligne',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: scheme.onSecondaryContainer),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.backup_outlined, color: scheme.onSurface),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sauvegarder mes favoris et notes',
                        style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: scheme.onSurface),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContentUpdateScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.cloud_sync_outlined, color: scheme.onSurface),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mises à jour du contenu',
                        style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: scheme.onSurface),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.primary, width: 2.5),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/chadrack_londe.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Chadrack Londe',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              'Fidèle méthodiste uni',
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: scheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Chadrack Londe coordonne le contenu francophone pour l'Afrique "
            "au sein de United Methodist Communications (UMCom) et est "
            "correspondant de UM News, le canal officiel d'information de "
            "l'Église Méthodiste Unie dans le monde. Basé en République "
            "Démocratique du Congo, il dirige aussi Radio Maniema Libertés "
            "à Kindu et met ses compétences techniques au service de "
            "l'Église et de sa communauté à travers des projets comme "
            "celui-ci. Fidèle méthodiste uni, il croit au pouvoir de la "
            "communication pour rapprocher les fidèles de la Parole de "
            "Dieu.",
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 28),
          Text(
            'Contact',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          _ContactTile(
            icon: Icons.phone,
            label: _phoneDisplay,
            onTap: () => _open('tel:$_phoneRaw'),
          ),
          _ContactTile(
            icon: Icons.email,
            label: _email,
            onTap: () => _open('mailto:$_email'),
          ),
          _ContactTile(
            icon: Icons.chat,
            label: 'WhatsApp',
            onTap: () => _open(_whatsapp),
          ),
          _ContactTile(
            icon: Icons.facebook,
            label: 'facebook.com/chadracklonde1',
            onTap: () => _open(_facebook),
          ),
          const SizedBox(height: 24),
          Text(
            'Ressources officielles UMC',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          _ResourceTile(
            icon: Icons.newspaper,
            title: 'UM News',
            subtitle: 'Service de presse officiel de l\'Église Méthodiste Unie',
            onTap: () => _open('https://umnews.org'),
          ),
          _ResourceTile(
            icon: Icons.church,
            title: 'UMC.org',
            subtitle: 'Site officiel de l\'Église Méthodiste Unie',
            onTap: () => _open('https://umc.org'),
          ),
          _ResourceTile(
            icon: Icons.menu_book_outlined,
            title: 'ResourceUMC',
            subtitle: 'Ressources pastorales et ministérielles',
            onTap: () => _open('https://resourceumc.org'),
          ),
          _ResourceTile(
            icon: Icons.facebook,
            title: 'Facebook — The United Methodist Church',
            subtitle: 'Page officielle',
            onTap: () => _open('https://facebook.com/unitedmethodistchurch'),
          ),
          _ResourceTile(
            icon: Icons.play_circle_outline,
            title: 'YouTube — United Methodist Videos',
            subtitle: 'Chaîne officielle (UMCom)',
            onTap: () => _open('https://youtube.com/@UMCVideos'),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'ÉMU Compagnon — développé avec foi pour l\'Église Méthodiste Unie',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ResourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.open_in_new, size: 18),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
