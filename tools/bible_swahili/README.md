# Bible swahilie (SCV) — source et import

- Texte : *Biblia Takatifu Wazi, Kiswahili* (Swahili Contemporary Version), édition Aionian (AionianBible.org), source eBible.org, © Biblica, Inc., 2018. Licence **Creative Commons Attribution-ShareAlike 4.0** (CC BY-SA 4.0). Original gratuit sur www.biblica.com et open.bible.
- Les PDF (10 fichiers fournis par le propriétaire) ne sont pas dans le dépôt ; le texte extrait l'est : `scv_verses.json` (31 102 versets, `[numéro du livre, chapitre, verset, texte]`).
- Les notes « Aionian » en petits caractères (par exemple « (Sheol h7585) ») sont écartées ; le texte biblique est conservé tel quel, avec les traits d'union de fin de ligne recollés.
- Import : `bible_verses` avec `version = 'SCV'`, le nom du livre étant le nom français canonique (comme pour LSG1910) ; l'index `bible_verses_fts` est reconstruit avec `INSERT INTO bible_verses_fts(bible_verses_fts) VALUES('rebuild')`.
- Scripts d'extraction : `survey.py`, `pg.py`, `build.py`, `parse.py` (chemins de travail de la session ; à adapter).
