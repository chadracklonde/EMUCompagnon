import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../shared/responsive/reading_width_constraint.dart';

/// "À propos" screen crediting the app's developer. Settings, backup,
/// content updates and the tutorial used to be linked from here; they now
/// live in the "Plus" tab.
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
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            AppCard(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.accent, width: 2),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/chadrack_londe.jpg',
                          fit: BoxFit.cover,
                          semanticLabel: 'Photo de Chadrack Londe',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Chadrack Londe',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fidèle méthodiste uni',
                      style: TextStyle(fontSize: 14.5, color: palette.muted),
                    ),
                    const SizedBox(height: 16),
                    Text(
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
                      style: TextStyle(fontSize: 15.5, height: 1.55, color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Contact'),
            AppRowGroup(rows: [
              AppRow(
                icon: Icons.phone_outlined,
                title: _phoneDisplay,
                trailingIcon: Icons.open_in_new,
                onTap: () => _open('tel:$_phoneRaw'),
              ),
              AppRow(
                icon: Icons.mail_outline,
                title: _email,
                trailingIcon: Icons.open_in_new,
                onTap: () => _open('mailto:$_email'),
              ),
              AppRow(
                icon: Icons.chat_outlined,
                title: 'WhatsApp',
                trailingIcon: Icons.open_in_new,
                onTap: () => _open(_whatsapp),
              ),
              AppRow(
                icon: Icons.facebook,
                title: 'Facebook',
                subtitle: 'facebook.com/chadracklonde1',
                trailingIcon: Icons.open_in_new,
                onTap: () => _open(_facebook),
              ),
            ]),
            const SizedBox(height: 24),
            const SectionTitle('Ressources officielles UMC'),
            AppRowGroup(rows: [
              AppRow(
                icon: Icons.newspaper,
                title: 'UM News',
                subtitle: "Service de presse officiel de l'Église Méthodiste Unie",
                trailingIcon: Icons.open_in_new,
                onTap: () => _open('https://umnews.org'),
              ),
              AppRow(
                icon: Icons.church_outlined,
                title: 'UMC.org',
                subtitle: "Site officiel de l'Église Méthodiste Unie",
                trailingIcon: Icons.open_in_new,
                onTap: () => _open('https://umc.org'),
              ),
              AppRow(
                icon: Icons.menu_book_outlined,
                title: 'ResourceUMC',
                subtitle: 'Ressources pastorales et ministérielles',
                trailingIcon: Icons.open_in_new,
                onTap: () => _open('https://resourceumc.org'),
              ),
              AppRow(
                icon: Icons.facebook,
                title: 'Facebook — The United Methodist Church',
                subtitle: 'Page officielle',
                trailingIcon: Icons.open_in_new,
                onTap: () => _open('https://facebook.com/unitedmethodistchurch'),
              ),
              AppRow(
                icon: Icons.play_circle_outline,
                title: 'YouTube — United Methodist Videos',
                subtitle: 'Chaîne officielle (UMCom)',
                trailingIcon: Icons.open_in_new,
                onTap: () => _open('https://youtube.com/@UMCVideos'),
              ),
            ]),
            const SizedBox(height: 24),
            Center(
              child: Text(
                "ÉMU Compagnon — développé avec foi pour l'Église Méthodiste Unie",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: palette.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
