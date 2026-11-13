import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/settings/app_settings.dart';

/// Keeps the screen on while [child] is shown — a hymn, a liturgy or a
/// prayer is read for minutes without touching the phone. Follows the
/// "Garder l'écran allumé" setting.
class KeepAwake extends StatefulWidget {
  final Widget child;
  const KeepAwake({super.key, required this.child});

  /// Number of [KeepAwake] widgets currently on screen: the lock is only
  /// released when the last one goes away (a hymn opened from the worship
  /// screen must not switch it off when it is closed).
  static int _holders = 0;

  @override
  State<KeepAwake> createState() => _KeepAwakeState();
}

class _KeepAwakeState extends State<KeepAwake> {
  bool _holding = false;

  void _apply(bool wanted) {
    if (wanted == _holding) return;
    _holding = wanted;
    KeepAwake._holders += wanted ? 1 : -1;
    // Unsupported platforms and tests have no wake lock: reading simply
    // goes on without it.
    WakelockPlus.toggle(enable: KeepAwake._holders > 0).catchError((_) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apply(context.watch<AppSettings>().keepScreenOn);
  }

  @override
  void dispose() {
    _apply(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
