# La Bible annotée : texte de la traduction et notes

> **STATUT : EN ATTENTE D'AUTORISATION. Ne pas importer dans l'application, ne pas publier,
> ne pas fusionner dans `main` avant la réponse écrite de Claude Royère (ThéoTeX).**
> Un message de demande lui a été envoyé (français et anglais) ; il porte sur le **texte de la
> traduction seulement**. **Les notes demandent une seconde autorisation**, à demander après la
> réponse au premier message. Tant que les réponses ne sont pas arrivées, ces fichiers servent
> seulement à préparer l'import.

## Source

- Numérisation de Claude Royère (ThéoTeX, theotex.org), 2004-2005. Ancien Testament de la Bible
  annotée (traduction de Félix Bovet et collaborateurs, 1879-1900) ; Nouveau Testament de Louis
  Bonnet (Ostervald remanié, 1846-1892), notes numérisées par Yves Petrakian.
- Le texte original de 1879-1900 est dans le domaine public ; cette saisie numérique a ses propres
  conditions, d'où la demande d'autorisation.
- Mention de crédit proposée à l'auteur : « La Bible annotée, numérisation ThéoTeX (Claude Royère),
  Nouveau Testament : notes numérisées par Yves Petrakian » avec un lien vers theotex.org.

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `ba_versets.json` | 31 173 versets, un objet par verset : `book`, `book_num`, `chapter`, `verse`, `text`. Noms de livres et ordre identiques à Louis Segond dans l'application. |
| `ba_notes.json` | 23 299 notes (18 Mo) : `book`, `book_num`, `chapter`, `verse` (0 = introduction de chapitre ou de section), `source` (AT/NT), `html` (balises simplifiées). **Ne pas importer sans la seconde autorisation.** |
| `CONTROLE.md` | Comparaison avec Louis Segond (chapitres de longueur différente, erreurs de la source). |
| `fetch_ot.py`, `fetch_ot_notes.py`, `fetch_nt.py` | Lecture lente du site (une page par seconde environ, identification claire). Seules les pages de traduction sont lues pour l'Ancien Testament ; le Nouveau Testament sert le texte et les notes dans la même page, les notes sont écartées à l'analyse. |
| `parse_ot.py`, `parse_nt.py` | Extraction des versets (texte seulement). |
| `parse_notes.py` | Extraction des notes de l'Ancien et du Nouveau Testament. |

Les pages HTML brutes ne sont pas dans le dépôt.

## Points à régler avant l'import

- Numérotation : 97 chapitres ont une longueur différente de Louis Segond (surtout les Psaumes, dont
  le titre compte comme un verset). Les fonctions qui relient les versions entre elles
  (verset du jour, favoris, plan de lecture, mémorisation) devront en tenir compte.
- Les vers de poésie contiennent des retours à la ligne (`\n`) à l'intérieur d'un verset.
- Corriger les fautes de saisie de la source (liste dans `CONTROLE.md`).
