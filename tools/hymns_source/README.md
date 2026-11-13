# Sources des cantiques « Chants de Victoire »

Fichiers fournis par le propriétaire du projet, conservés tels quels (ne pas supprimer) :

- `Chants-de-Victoire-CORRIGE.docx` : **source recommandée**. Une seule colonne, un paragraphe par vers, gras = numéro de couplet et refrain, titre en gras italique (« 152 Titre »), tonalité entre parenthèses.
- `Chants-de-Victoire-CORRIGE.txt` : extraction en deux colonnes entrelacées (type PDF) ; difficile à analyser, gardée pour mémoire.
- PDF : pas encore reçu.

Les cantiques de l'application sont dans `assets/db/app_data.db` (table `hymns`).

## Correction de la mise en forme (novembre 2026)

Scripts : `docx_parse.py` et `hymns.py` (lecture du .docx), `fix.py` (ajout du point après les numéros de couplet : « 1 Texte » devient « 1. Texte », « 1\. » devient « 1. »), `rebuild.py` (reconstruction à partir du .docx des cantiques dont la structure restait incorrecte). Seuls les cantiques mal affichés ont été modifiés. Le .docx s'arrête de façon fiable vers le n° 394 ; les n° 412 à 433 n'y figurent pas.
