import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/onboarding_service.dart';
import '../../../navigation/app_shell.dart';

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  const OnboardingPage({required this.icon, required this.title, required this.description});
}

const _pages = [
  OnboardingPage(
    icon: Icons.church_outlined,
    title: 'Bienvenue sur ÉMU Compagnon',
    description:
        "Votre compagnon de foi au quotidien : Bible, cantiques, "
        "dictionnaire biblique et liturgie, même sans connexion "
        "internet. Un tour rapide en quelques écrans avant de "
        "commencer.",
  ),
  OnboardingPage(
    icon: Icons.home_outlined,
    title: 'Accueil',
    description:
        "Votre page de lancement : le verset du jour, la "
        "progression de votre plan de lecture, le quiz du jour, et "
        "un accès rapide à l'Ancien et au Nouveau Testament, aux "
        "cantiques et à la liturgie.",
  ),
  OnboardingPage(
    icon: Icons.menu_book_outlined,
    title: 'Bible, Cantiques, Dictionnaire',
    description:
        "Pour lire, chercher et approfondir : la Bible complète "
        "avec concordance et le recueil Chants de Victoire "
        "(recherche par numéro, titre ou mot) dans leurs onglets, "
        "et un dictionnaire biblique et méthodiste dans l'onglet "
        "Plus.",
  ),
  OnboardingPage(
    icon: Icons.calendar_month_outlined,
    title: 'Liturgie et Favoris',
    description:
        "Le calendrier liturgique, l'ordre du culte et les "
        "sacrements dans l'onglet Liturgie. Touchez un verset pour "
        "l'ajouter aux favoris, le surligner ou y écrire une note — "
        "retrouvez le tout dans Plus, rubrique Favoris.",
  ),
  OnboardingPage(
    icon: Icons.self_improvement,
    title: 'Votre vie spirituelle',
    description:
        "Depuis l'accueil, dans « Vie spirituelle » : apprenez des "
        "versets par cœur avec la Mémorisation, tenez votre Journal "
        "de prière, faites l'Examen du soir et relevez le Défi de "
        "la semaine.",
  ),
  OnboardingPage(
    icon: Icons.lock_outline,
    title: 'Vos données restent chez vous',
    description:
        "Favoris, notes, journal et progression sont gardés "
        "uniquement sur votre téléphone. Pour les conserver ou les "
        "changer d'appareil, utilisez la sauvegarde dans l'onglet "
        "Plus. C'est aussi là que vous vérifiez les mises à jour "
        "du contenu.",
  ),
  OnboardingPage(
    icon: Icons.tune,
    title: 'À vous de personnaliser',
    description:
        "Mode sombre, taille du texte, langue de l'interface, "
        "rappel de lecture quotidien : tout se règle dans l'onglet "
        "Plus, rubrique Réglages. Vous pouvez y revoir ce tutoriel "
        "à tout moment. Bonne lecture !",
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    await OnboardingService.markCompleted();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      // Reached via "Revoir le tutoriel" from an existing screen (e.g.
      // À propos) — just return to it, don't stack a second AppShell.
      navigator.pop();
    } else {
      // Reached as the very first screen on cold start — replace it with
      // the real app, since there's nothing to pop back to.
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    }
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: TextButton(onPressed: _finish, child: const Text('Passer')),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final page = _pages[i];
                      return Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: palette.accentSoft,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Icon(page.icon, color: palette.accent, size: 44),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                page.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                page.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 15.5, height: 1.55, color: palette.muted),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Semantics(
                  label: 'Écran ${_index + 1} sur ${_pages.length}',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active ? palette.accent : palette.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(isLast ? 'Commencer' : 'Suivant'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
