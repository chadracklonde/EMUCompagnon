import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/app_theme.dart';

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

  static String _format(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: LinearProgressIndicator(),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: scheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? false;
              return IconButton.filled(
                tooltip: playing ? 'Pause' : 'Écouter',
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
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
                final totalMs = total.inMilliseconds.toDouble();
                return Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: position.inMilliseconds.toDouble().clamp(0, totalMs),
                        max: totalMs == 0 ? 1 : totalMs,
                        onChanged: (v) => _player.seek(Duration(milliseconds: v.round())),
                      ),
                    ),
                    Text(
                      '${_format(position)} / ${_format(total)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
