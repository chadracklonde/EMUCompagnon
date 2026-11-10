import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_cards.dart';
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
                    ? const EmptyState(
                        icon: Icons.menu_book_outlined,
                        message: 'Aucun verset en favori.\nTouchez un verset dans la Bible, '
                            'puis « Ajouter aux favoris ».',
                      )
                    : _list(
                        count: _verseFavorites.length,
                        itemBuilder: (context, index) {
                          final f = _verseFavorites[index];
                          return ResultRow(
                            title: f.verse.reference,
                            subtitle: f.verse.text,
                            subtitleMaxLines: 3,
                            accentTitle: true,
                            trailing: _removeButton(context, () => _removeVerse(f)),
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
                    ? const EmptyState(
                        icon: Icons.music_note_outlined,
                        message: "Aucun cantique en favori.\nTouchez l'étoile en haut d'un "
                            "cantique pour l'ajouter.",
                      )
                    : _list(
                        count: _hymnFavorites.length,
                        itemBuilder: (context, index) {
                          final f = _hymnFavorites[index];
                          return ResultRow(
                            leading: NumberBadge(f.hymn.number),
                            title: f.hymn.title,
                            trailing: _removeButton(context, () => _removeHymn(f)),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => HymnDetailScreen(hymn: f.hymn)),
                            ),
                          );
                        },
                      ),
                _verseNotes.isEmpty
                    ? const EmptyState(
                        icon: Icons.sticky_note_2_outlined,
                        message: "Aucune note pour l'instant.\nTouchez un verset dans la Bible, "
                            'puis « Ajouter une note ».',
                      )
                    : _list(
                        count: _verseNotes.length,
                        itemBuilder: (context, index) {
                          final e = _verseNotes[index];
                          return ResultRow(
                            title: e.verse.reference,
                            subtitle: e.note.noteText,
                            subtitleMaxLines: 3,
                            accentTitle: true,
                            trailing: Icon(
                              Icons.chevron_right,
                              color: AppPalette.of(context).muted,
                              size: 22,
                            ),
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

  Widget _list({required int count, required IndexedWidgetBuilder itemBuilder}) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: count,
      separatorBuilder: (_, __) => const Divider(indent: 20, endIndent: 20),
      itemBuilder: itemBuilder,
    );
  }

  Widget _removeButton(BuildContext context, VoidCallback onPressed) {
    return IconButton(
      tooltip: 'Retirer des favoris',
      icon: Icon(Icons.star, color: AppPalette.of(context).accent),
      onPressed: onPressed,
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
