import 'package:flutter/material.dart';
import '../../../core/models/hymn.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../hymns/repository/hymns_repository.dart';

/// Lets the user tick several hymns to add to a list. Pops with the
/// numbers ticked, in the order they were ticked.
class HymnPickerScreen extends StatefulWidget {
  /// Hymns already in the list: shown ticked and not selectable again.
  final List<String> alreadyIn;
  const HymnPickerScreen({super.key, required this.alreadyIn});

  @override
  State<HymnPickerScreen> createState() => _HymnPickerScreenState();
}

class _HymnPickerScreenState extends State<HymnPickerScreen> {
  final _repo = HymnsRepository();
  final _controller = TextEditingController();
  List<Hymn> _hymns = [];
  bool _loading = true;
  final List<String> _picked = [];
  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final seq = ++_searchSeq;
    List<Hymn> hymns;
    try {
      hymns = query.trim().isEmpty ? await _repo.getAll() : await _repo.search(query);
    } catch (_) {
      hymns = [];
    }
    // A slower, older query must not replace the results of a newer one.
    if (!mounted || seq != _searchSeq) return;
    setState(() {
      _hymns = hymns;
      _loading = false;
    });
  }

  void _toggle(String number) {
    setState(() => _picked.contains(number) ? _picked.remove(number) : _picked.add(number));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final count = _picked.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter des cantiques')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: count == 0 ? null : () => Navigator.pop(context, _picked),
            child: Text(
              count == 0
                  ? 'Cochez des cantiques'
                  : count == 1
                      ? 'Ajouter 1 cantique'
                      : 'Ajouter $count cantiques',
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Numéro, titre ou parole…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _hymns.isEmpty
                    ? const EmptyState(icon: Icons.search_off, message: 'Aucun cantique trouvé.')
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _hymns.length,
                        itemBuilder: (context, i) {
                          final hymn = _hymns[i];
                          final already = widget.alreadyIn.contains(hymn.number);
                          final picked = _picked.contains(hymn.number);
                          return ResultRow(
                            leading: NumberBadge(hymn.number),
                            title: hymn.title,
                            subtitle: already ? 'Déjà dans la liste' : null,
                            selected: picked,
                            trailing: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                already || picked
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: already
                                    ? palette.muted
                                    : picked
                                        ? palette.accent
                                        : palette.muted,
                                semanticLabel: picked ? 'Coché' : null,
                              ),
                            ),
                            onTap: already ? () {} : () => _toggle(hymn.number),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
