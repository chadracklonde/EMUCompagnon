import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Examen du soir')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_saved)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Déjà rempli aujourd\'hui — vous pouvez modifier vos réponses.',
                      style: TextStyle(fontSize: 12, color: scheme.outline),
                    ),
                  ),
                for (var i = 0; i < EveningExamenRepository.questions.length; i++) ...[
                  Text(
                    EveningExamenRepository.questions[i],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controllers[i],
                    maxLines: 3,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                ],
                FilledButton(
                  onPressed: _save,
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
    );
  }
}
