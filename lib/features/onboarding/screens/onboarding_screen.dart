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
    icon: Icons.church,
    title: 'Bienvenue sur ÉMU Compagnon',
    description:
        "Votre compagnon de foi au quotidien : Bible, cantiques, "
        "dictionnaire biblique et liturgie, même sans connexion "
        "internet. Un tour rapide en quelques écrans avant de "
        "commencer.",
  ),
  OnboardingPage(
    icon: Icons.home,
    title: 'Accueil',
    description:
        "Votre page de lancement : le verset du jour, un accès "
        "rapide à l'Ancien et au Nouveau Testament, au plan de "
        "lecture, aux cantiques et à la liturgie.",
  ),
  OnboardingPage(
    icon: Icons.menu_book,
    title: 'Bible, Cantiques, Dictionnaire',
    description:
        "Trois onglets pour lire, chercher et approfondir : la "
        "Bible complète avec concordance, le recueil Chants de "
        "Victoire, et un dictionnaire biblique et méthodiste.",
  ),
  OnboardingPage(
    icon: Icons.calendar_month,
    title: 'Liturgie et Favoris',
    description:
        "Le calendrier liturgique, l'ordre du culte et les "
        "sacrements dans l'onglet Liturgie. Marquez vos versets et "
        "cantiques préférés d'un tap sur l'étoile — retrouvez-les "
        "dans l'onglet Favoris, avec vos notes personnelles.",
  ),
  OnboardingPage(
    icon: Icons.tune,
    title: 'À vous de personnaliser',
    description:
        "Mode sombre, taille du texte, langue de l'interface, "
        "rappel de lecture quotidien : tout se règle depuis "
        "l'écran À propos. Bonne lecture !",
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

    return Scaffold(
      backgroundColor: UmcColors.burgundy,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Passer', style: TextStyle(color: Colors.white70)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: UmcColors.gold, width: 2),
                          ),
                          child: Icon(page.icon, color: UmcColors.gold, size: 44),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? UmcColors.gold : Colors.white30,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: UmcColors.gold,
                    foregroundColor: UmcColors.burgundy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _next,
                  child: Text(
                    isLast ? 'Commencer' : 'Suivant',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
