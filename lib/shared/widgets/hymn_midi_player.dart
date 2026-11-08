import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import '../../features/hymns/services/hymn_midi_service.dart';

/// Lecteur du MIDI d'un cantique : lecture/pause, arrêt, barre de position,
/// vitesse (pour suivre le rythme du chant à son aise) et répétition.
class HymnMidiPlayer extends StatefulWidget {
  final String assetPath;
  const HymnMidiPlayer({super.key, required this.assetPath});

  @override
  State<HymnMidiPlayer> createState() => _HymnMidiPlayerState();
}

class _HymnMidiPlayerState extends State<HymnMidiPlayer> {
  static const _tempos = [0.5, 0.75, 1.0, 1.25];

  final _service = HymnMidiService.instance;
  Timer? _poll;
  bool _loading = true;
  String? _error;
  MidiPlayerState? _state;
  double _tempo = 1.0;
  bool _loop = false;
  bool _dragging = false;
  double _dragValue = 0;

  bool get _playing => _state?.isPlaying ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _service.load(widget.assetPath);
      _state = await _service.state();
      _poll = Timer.periodic(const Duration(milliseconds: 250), (_) => _refresh());
    } catch (e) {
      _error = 'Impossible de charger la musique MIDI.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final s = await _service.state();
      if (mounted && !_dragging) setState(() => _state = s);
    } catch (_) {}
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _service.pause();
    } else {
      // Fin de morceau : on repart du début.
      if (_state?.status == MidiPlayerStatus.done) await _service.seek(0);
      await _service.play();
    }
    await _refresh();
  }

  Future<void> _stop() async {
    await _service.stop();
    await _refresh();
  }

  Future<void> _setTempo(double t) async {
    setState(() => _tempo = t);
    await _service.setTempo(t);
  }

  Future<void> _toggleLoop() async {
    setState(() => _loop = !_loop);
    await _service.setLoop(_loop);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _service.halt();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13)),
      );
    }

    final total = (_state?.totalTicks ?? 0).toDouble();
    final current = _dragging ? _dragValue : (_state?.currentTick ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 36),
                color: scheme.primary,
                tooltip: _playing ? 'Pause' : 'Écouter la musique',
                onPressed: _togglePlay,
              ),
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined, size: 30),
                tooltip: 'Arrêter',
                onPressed: _stop,
              ),
              Expanded(
                child: Slider(
                  value: current.clamp(0, total <= 0 ? 1 : total),
                  max: total <= 0 ? 1 : total,
                  onChangeStart: (v) => setState(() {
                    _dragging = true;
                    _dragValue = v;
                  }),
                  onChanged: (v) => setState(() => _dragValue = v),
                  onChangeEnd: (v) async {
                    await _service.seek(v.round());
                    setState(() => _dragging = false);
                    await _refresh();
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.repeat, color: _loop ? scheme.primary : null),
                tooltip: _loop ? 'Répétition activée' : 'Répéter',
                onPressed: _toggleLoop,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text('Vitesse', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                for (final t in _tempos)
                  ChoiceChip(
                    label: Text('${t}x'),
                    selected: _tempo == t,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => _setTempo(t),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
