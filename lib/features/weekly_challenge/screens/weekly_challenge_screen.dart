import 'package:flutter/material.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final challenge = WeeklyChallengeService.getCurrentChallenge();

    return Scaffold(
      appBar: AppBar(title: const Text('Défi de la semaine')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.flag_outlined, color: scheme.onPrimaryContainer, size: 32),
                          const SizedBox(height: 12),
                          Text(
                            'Cette semaine',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1,
                              color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            challenge,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _done,
                    onChanged: (v) => _toggle(v ?? false),
                    title: const Text('J\'ai relevé ce défi cette semaine'),
                  ),
                  const Spacer(),
                  Text(
                    'Un nouveau défi arrive chaque semaine.',
                    style: TextStyle(fontSize: 12, color: scheme.outline),
                  ),
                ],
              ),
            ),
    );
  }
}
