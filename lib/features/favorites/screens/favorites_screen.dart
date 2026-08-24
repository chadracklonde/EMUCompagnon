import 'package:flutter/material.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/bookmark.dart';
import '../../../core/models/verse.dart';
import '../../../core/models/hymn.dart';
import '../../../core/models/note.dart';
import '../repository/bookmark_repository.dart';
import '../../notes/repository/notes_repository.dart';
import '../../notes/screens/notes_sheet.dart';
import '../../bible/screens/chapter_screen.dart';
import '../../hymns/screens/hymn_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final _bookmarkRepo = BookmarkRepository();
  final _notesRepo = NotesRepository();
  late TabController _tabController;

  List<_VerseFavorite> _verseFavorites = [];
  List<_HymnFavorite> _hymnFavorites = [];
  List<_VerseNoteEntry> _verseNotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = await DbHelper.database;

    final verseBookmarks = await _bookmarkRepo.listByType(BookmarkType.verse);
    final verseFavorites = <_VerseFavorite>[];
    for (final b in verseBookmarks) {
      final rows = await db.query('bible_verses', where: 'id = ?', whereArgs: [b.refId], limit: 1);
      if (rows.isNotEmpty) {
        verseFavorites.add(_VerseFavorite(bookmark: b, verse: Verse.fromMap(rows.first)));
      }
    }

    final hymnBookmarks = await _bookmarkRepo.listByType(BookmarkType.hymn);
    final hymnFavorites = <_HymnFavorite>[];
    for (final b in hymnBookmarks) {
      final rows = await db.query('hymns', where: 'id = ?', whereArgs: [b.refId], limit: 1);
      if (rows.isNotEmpty) {
        hymnFavorites.add(_HymnFavorite(bookmark: b, hymn: Hymn.fromMap(rows.first)));
      }
    }

    final notes = await _notesRepo.listAll(BookmarkType.verse);
    final verseNotes = <_VerseNoteEntry>[];
    for (final n in notes) {
      final rows = await db.query('bible_verses', where: 'id = ?', whereArgs: [n.refId], limit: 1);
      if (rows.isNotEmpty) {
        verseNotes.add(_VerseNoteEntry(note: n, verse: Verse.fromMap(rows.first)));
      }
    }

    if (mounted) {
      setState(() {
        _verseFavorites = verseFavorites;
        _hymnFavorites = hymnFavorites;
        _verseNotes = verseNotes;
        _loading = false;
      });
    }
  }

  Future<void> _removeVerse(_VerseFavorite f) async {
    await _bookmarkRepo.remove(f.bookmark.id);
    _load();
  }

  Future<void> _removeHymn(_HymnFavorite f) async {
    await _bookmarkRepo.remove(f.bookmark.id);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoris'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Versets (${_verseFavorites.length})'),
            Tab(text: 'Cantiques (${_hymnFavorites.length})'),
            Tab(text: 'Notes (${_verseNotes.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _verseFavorites.isEmpty
                    ? const _EmptyState(
                        icon: Icons.menu_book,
                        message: 'Aucun verset en favori.\nAppuyez sur l\'étoile à côté d\'un verset pour l\'ajouter.',
                      )
                    : ListView.separated(
                        itemCount: _verseFavorites.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final f = _verseFavorites[index];
                          return ListTile(
                            title: Text(f.verse.reference, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(f.verse.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.star, color: Colors.amber),
                              onPressed: () => _removeVerse(f),
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChapterScreen(
                                  book: f.verse.book,
                                  chapter: f.verse.chapter,
                                  highlightVerse: f.verse.verse,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                _hymnFavorites.isEmpty
                    ? const _EmptyState(
                        icon: Icons.music_note,
                        message: 'Aucun cantique en favori.\nAppuyez sur l\'étoile en haut d\'un cantique pour l\'ajouter.',
                      )
                    : ListView.separated(
                        itemCount: _hymnFavorites.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final f = _hymnFavorites[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text(f.hymn.number)),
                            title: Text(f.hymn.title),
                            trailing: IconButton(
                              icon: const Icon(Icons.star, color: Colors.amber),
                              onPressed: () => _removeHymn(f),
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => HymnDetailScreen(hymn: f.hymn)),
                            ),
                          );
                        },
                      ),
                _verseNotes.isEmpty
                    ? const _EmptyState(
                        icon: Icons.sticky_note_2_outlined,
                        message: 'Aucune note pour l\'instant.\nOuvrez le menu « ⋮ » d\'un verset pour en écrire une.',
                      )
                    : ListView.separated(
                        itemCount: _verseNotes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final e = _verseNotes[index];
                          return ListTile(
                            title: Text(e.verse.reference, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(e.note.noteText, maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: () => showNotesSheet(
                              context,
                              type: BookmarkType.verse,
                              refId: e.verse.id,
                              label: e.verse.reference,
                            ).then((_) => _load()),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}

class _VerseFavorite {
  final Bookmark bookmark;
  final Verse verse;
  _VerseFavorite({required this.bookmark, required this.verse});
}

class _HymnFavorite {
  final Bookmark bookmark;
  final Hymn hymn;
  _HymnFavorite({required this.bookmark, required this.hymn});
}

class _VerseNoteEntry {
  final VerseNote note;
  final Verse verse;
  _VerseNoteEntry({required this.note, required this.verse});
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}
