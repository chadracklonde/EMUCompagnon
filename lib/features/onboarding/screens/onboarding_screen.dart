import '../../audio_pack/screens/audio_pack_offer_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../services/onboarding_service.dart';
import '../../../navigation/app_shell.dart';

/// Les icônes des écrans du tutoriel ; leur texte est dans `AppStrings`
/// (clés `onb1_title`, `onb1_desc`, …), en français et en swahili.
const _pageIcons = [
  Icons.church_outlined,
  Icons.home_outlined,
  Icons.menu_book_outlined,
  Icons.calendar_month_outlined,
  Icons.self_improvement,
  Icons.lock_outline,
  Icons.tune,
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
      final offer = await AudioPackOffer.shouldShow(context.read<AppSettings>().locale);
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => offer
              ? AudioPackOfferScreen(next: (_) => const AppShell())
              : const AppShell(),
        ),
      );
    }
  }

  void _next() {
    if (_index == _pageIcons.length - 1) {
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
    final locale = context.watch<AppSettings>().locale;
    String t(String key) => AppStrings.t(key, locale);
    final isLast = _index == _pageIcons.length - 1;
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
                    child: TextButton(onPressed: _finish, child: Text(t('onb_skip'))),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pageIcons.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
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
                                child: Icon(_pageIcons[i], color: palette.accent, size: 44),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                t('onb${i + 1}_title'),
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
                                t('onb${i + 1}_desc'),
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
                  label: AppStrings.tf('onb_screen_n', locale, {'i': _index + 1, 'n': _pageIcons.length}),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pageIcons.length, (i) {
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
                      child: Text(t(isLast ? 'onb_start' : 'onb_next')),
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
