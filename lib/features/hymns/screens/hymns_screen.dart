import 'package:flutter/material.dart';
import '../../../core/models/hymn.dart';
import '../repository/hymns_repository.dart';
import 'hymn_detail_screen.dart';

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
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
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
      setState(() => _searching = false);
      _loadAll();
      return;
    }
    setState(() => _searching = true);
    final results = await _repo.search(query);
    if (mounted) setState(() => _hymns = results);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chants de Victoire'),
      ),
      body: Column(
        children: [
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
