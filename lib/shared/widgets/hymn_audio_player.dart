import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Compact play/pause/progress bar for a hymn's recorded melody.
/// Only ever instantiated when [audioUrl] is non-null — see HymnDetailScreen.
class HymnAudioPlayer extends StatefulWidget {
  final String audioUrl;
  const HymnAudioPlayer({super.key, required this.audioUrl});

  @override
  State<HymnAudioPlayer> createState() => _HymnAudioPlayerState();
}

class _HymnAudioPlayerState extends State<HymnAudioPlayer> {
  final _player = AudioPlayer();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.audioUrl);
    } catch (e) {
      _error = "Impossible de charger l'audio.";
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? false;
              return IconButton(
                icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 36),
                color: scheme.primary,
                onPressed: () => playing ? _player.pause() : _player.play(),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final total = _player.duration ?? Duration.zero;
                return Slider(
                  value: position.inMilliseconds.toDouble().clamp(0, total.inMilliseconds.toDouble()),
                  max: total.inMilliseconds.toDouble() == 0 ? 1 : total.inMilliseconds.toDouble(),
                  onChanged: (v) => _player.seek(Duration(milliseconds: v.round())),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
