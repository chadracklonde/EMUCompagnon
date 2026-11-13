import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/services/widget_catalog.dart';
import '../../../core/services/widget_sync_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';

/// Lists the widgets of the Android home screen and offers to place each
/// one, so they can be found without hunting in the phone's widget list.
class WidgetsScreen extends StatefulWidget {
  const WidgetsScreen({super.key});

  @override
  State<WidgetsScreen> createState() => _WidgetsScreenState();
}

class _WidgetsScreenState extends State<WidgetsScreen> {
  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  late final Future<int?> _count = WidgetSyncService.installedCount();

  Future<void> _add(WidgetInfo widget) async {
    final placed = await WidgetSyncService.pin(widget.key);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(placed
            ? "Confirmez l'ajout dans la fenêtre du téléphone."
            : "Votre téléphone ne permet pas l'ajout direct. Appuyez longuement sur "
                "l'écran d'accueil, choisissez « Widgets », puis ÉMU Compagnon."),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Widgets de l'écran d'accueil")),
      body: ReadingWidthConstraint(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (!_isAndroid)
              const InfoNote("Les widgets sont disponibles sur les téléphones Android.")
            else ...[
              FutureBuilder<int?>(
                future: _count,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(height: 48);
                  }
                  final count = snapshot.data;
                  return InfoNote(count == null || count == 0
                      ? "Cette version de l'application ne contient pas les widgets. "
                          "Installez la dernière version pour les obtenir."
                      : '$count widgets sont disponibles dans cette version.');
                },
              ),
              const SizedBox(height: 12),
              const InfoNote(
                "Touchez « Ajouter » pour placer un widget sur l'écran d'accueil. "
                "Vous pouvez aussi appuyer longuement sur l'écran d'accueil, choisir "
                "« Widgets », puis ÉMU Compagnon.",
              ),
              const SizedBox(height: 24),
              for (final family in WidgetCatalog.families) ...[
                SectionTitle(family),
                AppCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < WidgetCatalog.inFamily(family).length; i++) ...[
                        if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: palette.border),
                        ListTile(
                          title: Text(
                            WidgetCatalog.inFamily(family)[i].label,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            WidgetCatalog.inFamily(family)[i].description,
                            style: TextStyle(fontSize: 13, color: palette.muted),
                          ),
                          trailing: TextButton(
                            onPressed: () => _add(WidgetCatalog.inFamily(family)[i]),
                            child: const Text('Ajouter'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
