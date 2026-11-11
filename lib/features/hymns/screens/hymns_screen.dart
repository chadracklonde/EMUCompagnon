import 'package:flutter/material.dart';
import '../../../core/models/hymn.dart';
import '../repository/hymns_repository.dart';
import 'hymn_detail_screen.dart';
import '../../hymn_lists/screens/hymn_lists_screen.dart';
import '../../../core/services/reading_history_service.dart';
import '../../../shared/widgets/text_settings_popup.dart';
import '../../../shared/responsive/responsive.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../core/theme/app_theme.dart';

class HymnsScreen extends StatefulWidget {
  const HymnsScreen({super.key});

  @override
  State<HymnsScreen> createState() => _HymnsScreenState();
}

class _HymnsScreenState extends State<HymnsScreen> {
  final _repo = HymnsRepository();
  final _searchController = TextEditingController();
  List<Hymn> _hymns = [];
  bool _loading = true;
  ({String number, String title})? _lastRead;
  // Only meaningful in the wide (master-detail) layout.
  Hymn? _selectedHymn;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadLastRead();
  }

  void _loadLastRead() {
    ReadingHistoryService.getLastHymnRead().then((r) {
      if (mounted) setState(() => _lastRead = r);
    });
  }

  /// Opens a hymn full-screen, then refreshes "Reprendre" on return (this
  /// tab stays alive in the shell, so it would otherwise go stale).
  Future<void> _push(Hymn hymn) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HymnDetailScreen(hymn: hymn)),
    );
    if (mounted) _loadLastRead();
  }

  Future<void> _loadAll() async {
    final hymns = await _repo.getAll();
    if (mounted) {
      setState(() {
        _hymns = hymns;
        _loading = false;
      });
    }
  }

  // Incremented on every keystroke so a slow, older query can never
  // overwrite the results of a newer one (typing "gra" then "grand"
  // could otherwise end up showing the "gra" results).
  int _searchSeq = 0;
  bool _isSearching = false;

  String? _searchError;

  Future<void> _onSearchChanged(String query) async {
    final seq = ++_searchSeq;
    final searching = query.trim().isNotEmpty;
    try {
      final hymns = searching ? await _repo.search(query) : await _repo.getAll();
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _hymns = hymns;
        _isSearching = searching;
        _searchError = null;
        _loading = false;
      });
    } catch (e) {
      // Never fail silently (the list would just stay unchanged and look
      // like "search does nothing"): show what went wrong.
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _hymns = [];
        _isSearching = true;
        _searchError = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openLastHymn(bool isWide) async {
    if (_lastRead == null) return;
    final hymn = await _repo.getByNumber(_lastRead!.number);
    if (hymn == null || !mounted) return;
    if (isWide) {
      setState(() => _selectedHymn = hymn);
    } else {
      _push(hymn);
    }
  }

  void _openHymn(Hymn h, bool isWide) {
    if (isWide) {
      setState(() => _selectedHymn = h);
    } else {
      _push(h);
    }
  }

  Widget _buildList(bool isWide) {
    final palette = AppPalette.of(context);
    final showResume = _lastRead != null && !_isSearching;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Numéro, titre ou parole…',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_isSearching && _hymns.isEmpty)
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _searchError == null
                              ? 'Aucun cantique trouvé.'
                              : 'Recherche indisponible : $_searchError',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.muted),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _hymns.length + (showResume ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (showResume && index == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: AppCard(
                              child: AppRow(
                                icon: Icons.history,
                                title: 'Reprendre',
                                subtitle: 'N° ${_lastRead!.number} · ${_lastRead!.title}',
                                onTap: () => _openLastHymn(isWide),
                              ),
                            ),
                          );
                        }
                        final h = _hymns[index - (showResume ? 1 : 0)];
                        return _HymnRow(
                          hymn: h,
                          selected: isWide && _selectedHymn?.id == h.id,
                          onTap: () => _openHymn(h, isWide),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chants de Victoire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            tooltip: 'Listes de cantiques',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HymnListsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Taille du texte',
            onPressed: () => showTextSettingsPopup(context),
          ),
        ],
      ),
      body: !isWide
          ? _buildList(false)
          : Row(
              children: [
                SizedBox(width: 380, child: _buildList(true)),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _selectedHymn == null
                      ? Center(
                          child: Text(
                            'Sélectionnez un cantique',
                            style: TextStyle(color: Theme.of(context).colorScheme.outline),
                          ),
                        )
                      : HymnDetailScreen(hymn: _selectedHymn!, showBackButton: false),
                ),
              ],
            ),
    );
  }
}

class _HymnRow extends StatelessWidget {
  final Hymn hymn;
  final bool selected;
  final VoidCallback onTap;
  const _HymnRow({required this.hymn, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? palette.accentSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hymn.number,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hymn.title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (hymn.key != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Tonalité : ${hymn.key}',
                          style: TextStyle(fontSize: 12.5, color: palette.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
