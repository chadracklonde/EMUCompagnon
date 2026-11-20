"""Intègre la Bible annotée à l'application.

1. Ajoute le texte (version « BA ») à assets/db/app_data.db, avec l'index de recherche.
2. Crée assets/db/bible_notes.db avec les notes (copiée au premier usage, comme app_data.db).

Usage : python3 -I tools/bible_annotee/build_db.py
Relancer le script est sans danger : les lignes « BA » sont remplacées, rien d'autre ne bouge.
Les identifiants des versets des autres versions ne changent pas (les nouveaux viennent après).
"""
import json, os, sqlite3

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
APP_DB = os.path.join(ROOT, 'assets', 'db', 'app_data.db')
NOTES_DB = os.path.join(ROOT, 'assets', 'db', 'bible_notes.db')
VERSION = 'BA'

verses = json.load(open(os.path.join(HERE, 'ba_versets.json'), encoding='utf8'))
notes = json.load(open(os.path.join(HERE, 'ba_notes.json'), encoding='utf8'))

# --- 1. Texte
db = sqlite3.connect(APP_DB)
# Les noms et numéros de livres sont ceux de Louis Segond dans la base.
lsg = {b: n for b, n in db.execute("SELECT book, MIN(book_num) FROM bible_verses WHERE version='LSG1910' GROUP BY book")}
bad = {v['book'] for v in verses if lsg.get(v['book']) != v['book_num']}
assert not bad, f'livres inconnus ou mal numérotés : {bad}'
db.execute('DELETE FROM bible_verses WHERE version = ?', (VERSION,))
db.executemany(
    'INSERT INTO bible_verses (book, book_num, chapter, verse, text, version) VALUES (?,?,?,?,?,?)',
    [(v['book'], v['book_num'], v['chapter'], v['verse'], v['text'], VERSION) for v in verses],
)
db.execute("INSERT INTO bible_verses_fts(bible_verses_fts) VALUES('rebuild')")
db.commit()
n = db.execute('SELECT COUNT(*) FROM bible_verses WHERE version = ?', (VERSION,)).fetchone()[0]
db.execute('VACUUM')
db.close()
print(f'{n} versets {VERSION} dans {os.path.relpath(APP_DB, ROOT)} ({os.path.getsize(APP_DB) / 1e6:.1f} Mo)')

# --- 2. Notes
if os.path.exists(NOTES_DB):
    os.remove(NOTES_DB)
nd = sqlite3.connect(NOTES_DB)
nd.execute('''CREATE TABLE bible_notes (
    version TEXT NOT NULL, book TEXT NOT NULL, chapter INTEGER NOT NULL,
    verse INTEGER NOT NULL, ord INTEGER NOT NULL, html TEXT NOT NULL)''')
nd.execute('CREATE INDEX bible_notes_chapter ON bible_notes(version, book, chapter)')
nd.executemany(
    'INSERT INTO bible_notes VALUES (?,?,?,?,?,?)',
    [(VERSION, x['book'], x['chapter'], x['verse'], i, x['html']) for i, x in enumerate(notes)],
)
nd.execute('PRAGMA user_version = 1')
nd.commit()
m = nd.execute('SELECT COUNT(*) FROM bible_notes').fetchone()[0]
nd.execute('VACUUM')
nd.close()
print(f'{m} notes dans {os.path.relpath(NOTES_DB, ROOT)} ({os.path.getsize(NOTES_DB) / 1e6:.1f} Mo)')
