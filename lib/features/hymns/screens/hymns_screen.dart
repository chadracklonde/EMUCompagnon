import 'package:flutter/material.dart';
import '../../../core/models/hymn.dart';
import '../repository/hymns_repository.dart';
import 'hymn_detail_screen.dart';
import '../../../core/services/reading_history_service.dart';
import '../../../shared/widgets/text_settings_popup.dart';
import '../../../shared/responsive/responsive.dart';

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
    ReadingHistoryService.getLastHymnRead().then((r) {
      if (mounted) setState(() => _lastRead = r);
    });
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

  Future<void> _onSearchChanged(String query) async {
    final seq = ++_searchSeq;
    final searching = query.trim().isNotEmpty;
    final hymns = searching ? await _repo.search(query) : await _repo.getAll();
    if (!mounted || seq != _searchSeq) return;
    setState(() {
      _hymns = hymns;
      _isSearching = searching;
      _loading = false;
    });
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
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HymnDetailScreen(hymn: hymn)),
      );
    }
  }

  void _openHymn(Hymn h, bool isWide) {
    if (isWide) {
      setState(() => _selectedHymn = h);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HymnDetailScreen(hymn: h)),
      );
    }
  }

  Widget _buildList(bool isWide) {
    return Column(
      children: [
        if (_lastRead != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openLastHymn(isWide),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Reprendre — N° ${_lastRead!.number} ${_lastRead!.title}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Numéro, titre ou parole…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
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
                          'Aucun cantique trouvé.',
                          style: TextStyle(color: Theme.of(context).colorScheme.outline),
                        ),
                      ),
                    )
                  : ListView.builder(
                  itemCount: _hymns.length,
                  itemBuilder: (context, index) {
                    final h = _hymns[index];
                    final selected = isWide && _selectedHymn?.id == h.id;
                    return ListTile(
                      selected: selected,
                      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                      leading: CircleAvatar(child: Text(h.number)),
                      title: Text(h.title),
                      subtitle: h.key != null ? Text('Tonalité : ${h.key}') : null,
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
