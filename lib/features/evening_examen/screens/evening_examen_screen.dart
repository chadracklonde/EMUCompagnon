import 'package:flutter/material.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../repository/evening_examen_repository.dart';

/// Short end-of-day reflection ("examen"), in the Wesleyan tradition of
/// daily self-examination — a complement to the morning verse/devotional
/// rhythm. Answers are private and local, one set per calendar day.
class EveningExamenScreen extends StatefulWidget {
  const EveningExamenScreen({super.key});

  @override
  State<EveningExamenScreen> createState() => _EveningExamenScreenState();
}

class _EveningExamenScreenState extends State<EveningExamenScreen> {
  final _repo = EveningExamenRepository();
  late final List<TextEditingController> _controllers = List.generate(
    EveningExamenRepository.questions.length,
    (_) => TextEditingController(),
  );
  bool _loading = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final existing = await _repo.getToday();
    if (!mounted) return;
    if (existing != null) {
      for (var i = 0; i < _controllers.length && i < existing.answers.length; i++) {
        _controllers[i].text = existing.answers[i];
      }
      _saved = true;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final answers = _controllers.map((c) => c.text.trim()).toList();
    await _repo.upsertToday(answers);
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Examen du soir enregistré.')),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final questions = EveningExamenRepository.questions;
    return Scaffold(
      appBar: AppBar(title: const Text('Examen du soir')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ReadingWidthConstraint(
              maxWidth: 640,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  InfoNote(
                    _saved
                        ? "Déjà rempli aujourd'hui — vous pouvez modifier vos réponses."
                        : 'Quelques minutes pour relire votre journée. Vos réponses '
                            'restent sur cet appareil.',
                  ),
                  const SizedBox(height: 24),
                  for (var i = 0; i < questions.length; i++) ...[
                    Text(
                      questions[i],
                      style: TextStyle(
                        fontSize: 15.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _controllers[i],
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Votre réponse…'),
                    ),
                    const SizedBox(height: 22),
                  ],
                  FilledButton(onPressed: _save, child: const Text('Enregistrer')),
                ],
              ),
            ),
    );
  }
}
