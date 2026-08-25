import 'package:flutter/material.dart';
import '../../../core/models/hymn.dart';
import '../repository/hymns_repository.dart';
import 'hymn_detail_screen.dart';
import '../../../core/services/reading_history_service.dart';
import '../../../shared/widgets/text_settings_popup.dart';

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

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      _loadAll();
      return;
    }
    final results = await _repo.search(query);
    if (mounted) setState(() => _hymns = results);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openLastHymn() async {
    if (_lastRead == null) return;
    final hymn = await _repo.getByNumber(_lastRead!.number);
    if (hymn != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HymnDetailScreen(hymn: hymn)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          if (_lastRead != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _openLastHymn,
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
                : ListView.builder(
                    itemCount: _hymns.length,
                    itemBuilder: (context, index) {
                      final h = _hymns[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(h.number)),
                        title: Text(h.title),
                        subtitle: h.key != null ? Text('Tonalité : ${h.key}') : null,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => HymnDetailScreen(hymn: h)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
