import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../core/services/weekly_challenge_service.dart';

/// Shows this week's spiritual-practice challenge and lets the user mark
/// it as taken up. A new theme rotates in automatically each week —
/// purely local, no server, no social/ranking component.
class WeeklyChallengeScreen extends StatefulWidget {
  const WeeklyChallengeScreen({super.key});

  @override
  State<WeeklyChallengeScreen> createState() => _WeeklyChallengeScreenState();
}

class _WeeklyChallengeScreenState extends State<WeeklyChallengeScreen> {
  bool _loading = true;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final done = await WeeklyChallengeService.isCurrentCompleted();
    if (mounted) setState(() {
      _done = done;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    await WeeklyChallengeService.setCurrentCompleted(value);
    setState(() => _done = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final challenge = WeeklyChallengeService.getCurrentChallenge();

    return Scaffold(
      appBar: AppBar(title: const Text('Défi de la semaine')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ReadingWidthConstraint(
              maxWidth: 640,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppPalette.hero,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.flag_outlined, color: AppPalette.onHero, size: 28),
                        const SizedBox(height: 14),
                        const Text(
                          'CETTE SEMAINE',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: AppPalette.onHeroMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          challenge,
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 20,
                            height: 1.4,
                            color: AppPalette.onHero,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    onTap: () => _toggle(!_done),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _done,
                            onChanged: (v) => _toggle(v ?? false),
                            shape: const CircleBorder(),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "J'ai relevé ce défi cette semaine",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Un nouveau défi arrive chaque semaine.',
                    style: TextStyle(fontSize: 13, color: palette.muted),
                  ),
                ],
              ),
            ),
    );
  }
}
