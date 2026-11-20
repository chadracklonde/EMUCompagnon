# La Bible annotée : texte de la traduction et notes

> **STATUT : AUTORISÉ.** Claude Royère (ThéoTeX) a répondu par écrit le 20 novembre 2026 : il
> autorise l'usage de la Bible annotée dans l'application, texte de la traduction **et notes**, et
> a envoyé lui-même ses fichiers `ba.zip` (Ancien Testament) et `nta.zip` (Nouveau Testament), qui
> se sont révélés identiques, octet pour octet, aux pages de son site lues par les scripts ci-dessous.
> **Crédit demandé : un lien vers theotex.org**, pour que les lecteurs y trouvent de la lecture gratuite.

## Source

- Numérisation de Claude Royère (ThéoTeX, theotex.org), 2004-2005. Ancien Testament de la Bible
  annotée (traduction de Félix Bovet et collaborateurs, 1879-1900) ; Nouveau Testament de Louis
  Bonnet (Ostervald remanié, 1846-1892), notes numérisées par Yves Petrakian.
- Le texte original de 1879-1900 est dans le domaine public ; cette saisie numérique a ses propres
  conditions, d'où la demande d'autorisation.
- Crédit demandé par l'auteur : un lien vers theotex.org. Nous y ajoutons le nom de l'œuvre et des
  numériseurs : « La Bible annotée, numérisation ThéoTeX (Claude Royère), Nouveau Testament : notes
  numérisées par Yves Petrakian — theotex.org ».

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `ba_versets.json` | 31 173 versets, un objet par verset : `book`, `book_num`, `chapter`, `verse`, `text`. Noms de livres et ordre identiques à Louis Segond dans l'application. |
| `ba_notes.json` | 23 299 notes (18 Mo) : `book`, `book_num`, `chapter`, `verse` (0 = introduction de chapitre ou de section), `source` (AT/NT), `html` (balises simplifiées).  |
| `CONTROLE.md` | Comparaison avec Louis Segond (chapitres de longueur différente, erreurs de la source). |
| `fetch_ot.py`, `fetch_ot_notes.py`, `fetch_nt.py` | Lecture lente du site (une page par seconde environ, identification claire). Seules les pages de traduction sont lues pour l'Ancien Testament ; le Nouveau Testament sert le texte et les notes dans la même page, les notes sont écartées à l'analyse. |
| `parse_ot.py`, `parse_nt.py` | Extraction des versets (texte seulement). |
| `parse_notes.py` | Extraction des notes de l'Ancien et du Nouveau Testament. |

Les pages HTML brutes ne sont pas dans le dépôt. Les archives de l'auteur contiennent aussi les
cartes et les tableaux : non extraits.

Les introductions de livres (`intros_ba`, `intros_nta` des archives de l'auteur, autorisées par lui le
20 novembre 2026) sont extraites par `parse_intros.py` dans `ba_intros.json` : 66 textes (introductions,
introductions de groupes de livres, et trois études : la Création de F. Godet, Job, le Cantique),
reliés à 71 emplacements livre → texte. Les textes communs à deux livres (Samuel, Rois, Chroniques,
Esdras-Néhémie, 2e et 3e Jean) sont rattachés aux deux. Les appels de note deviennent des exposants
(¹ ²) et les notes sont rassemblées sous un intertitre « Notes ». `build_db.py` les range dans la
table `book_intros` de `assets/db/bible_notes.db`.

## Points à régler avant l'import

- Numérotation : 97 chapitres ont une longueur différente de Louis Segond (surtout les Psaumes, dont
  le titre compte comme un verset). Les fonctions qui relient les versions entre elles
  (verset du jour, favoris, plan de lecture, mémorisation) devront en tenir compte.
- Les vers de poésie contiennent des retours à la ligne (`\n`) à l'intérieur d'un verset.
- Corriger les fautes de saisie de la source (liste dans `CONTROLE.md`).
