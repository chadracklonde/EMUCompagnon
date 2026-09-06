import 'package:flutter/material.dart';
import '../../../core/models/dictionary_entry.dart';
import '../repository/dictionary_repository.dart';
import 'dictionary_detail_screen.dart';
import '../../../shared/responsive/responsive.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _repo = DictionaryRepository();
  final _searchController = TextEditingController();
  List<DictionaryEntry> _entries = [];
  bool _loading = true;
  // Only meaningful in the wide (master-detail) layout.
  DictionaryEntry? _selectedEntry;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final entries = await _repo.getAll();
    if (mounted) {
      setState(() {
        _entries = entries;
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
    if (mounted) setState(() => _entries = results);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEntry(DictionaryEntry e, bool isWide) {
    if (isWide) {
      setState(() => _selectedEntry = e);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DictionaryDetailScreen(entry: e)),
      );
    }
  }

  Widget _buildList(bool isWide) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un terme…',
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
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final e = _entries[index];
                    final selected = isWide && _selectedEntry?.id == e.id;
                    return ListTile(
                      selected: selected,
                      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                      title: Text(e.term, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        e.definition,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _openEntry(e, isWide),
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
      appBar: AppBar(title: const Text('Dictionnaire biblique')),
      body: !isWide
          ? _buildList(false)
          : Row(
              children: [
                SizedBox(width: 380, child: _buildList(true)),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _selectedEntry == null
                      ? Center(
                          child: Text(
                            'Sélectionnez un terme',
                            style: TextStyle(color: Theme.of(context).colorScheme.outline),
                          ),
                        )
                      : DictionaryDetailScreen(entry: _selectedEntry!, showBackButton: false),
                ),
              ],
            ),
    );
  }
}
