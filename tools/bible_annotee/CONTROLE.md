# Contrôle contre Louis Segond 1910 (base de l'application)

- Versets extraits : 31173 (Louis Segond : 31102)
- Chapitres : 1189 (Louis Segond : 1189), aucun manquant, aucun verset vide, aucun trou de numérotation
- Chapitres de même longueur que Louis Segond : 1092 ; de longueur différente : 97
- Versets que la source découpe en deux lignes et que le script réunit : 7 (Job 10:3, Psaumes 139:15, Luc 9:43, Jean 19:16, Actes 9:19, 2 Pierre 2:13, Jude 1:8)

Les écarts viennent de la numérotation des versets (titres de psaumes comptés comme versets, versets coupés ou réunis autrement), pas de pertes de texte.

## Erreurs de la source repérées (à corriger à la main avant import)

- Romains 8:28 : « de ceux. qui aiment Dieu » (point en trop dans la saisie)

## Notes (fichier `ba_notes.json`)

- 23 299 notes : 16 923 pour l'Ancien Testament, 6 376 pour le Nouveau Testament. Tous les livres ont des notes.
- 669 notes d'introduction de chapitre ou de section (verset 0).
- Balises conservées : `p`, `i` (italique), `b` (mot commenté), `h` (titre), `ref` (référence biblique), `ul`, `li`, `br`.
- Poids : 18 Mo en JSON, environ 5,7 Mo compressé : à proposer comme **pack à télécharger** plutôt que dans l'application.
- Les introductions de livres sont extraites (`ba_intros.json`, voir README). Un « & » égaré dans la source (Romains, avant « Schurer ») est remplacé par une espace ; les guillemets `<< >>` de la source deviennent « ».

### Défauts de la source repérés (à corriger à la main avant import)

- Notes rattachées à un verset qui n'existe pas dans le texte (faute de numérotation de la source) :
  Lévitique 15:34, Josué 12:31, 2 Chroniques 19:14, Psaumes 145:24, Esaïe 47:45, Ezéchiel 44:34, Daniel 1:24.
- Balises mal imbriquées dans la source : Genèse 16:13, Luc 13:1 (le texte reste lisible).
- Notes vides : 1 Samuel 18 (verset 0), Jean 16:5.
- Luc 9:1-9 : la page du Nouveau Testament annoté n'a pas de notes (texte seul).

## Chapitres dont la longueur diffère de Louis Segond

| Livre | Chapitre | Annotée | Louis Segond |
|---|---|---|---|
| Nombres | 12 | 15 | 16 |
| Nombres | 13 | 34 | 33 |
| Nombres | 29 | 39 | 40 |
| Nombres | 30 | 17 | 16 |
| Deutéronome | 22 | 29 | 30 |
| Deutéronome | 23 | 26 | 25 |
| 1 Samuel | 20 | 43 | 42 |
| 1 Samuel | 23 | 28 | 29 |
| 1 Samuel | 24 | 23 | 22 |
| 2 Samuel | 12 | 32 | 31 |
| 1 Rois | 22 | 54 | 53 |
| 2 Rois | 11 | 20 | 21 |
| Job | 38 | 38 | 41 |
| Job | 39 | 38 | 30 |
| Job | 40 | 28 | 24 |
| Job | 41 | 25 | 34 |
| Psaumes | 3 | 9 | 8 |
| Psaumes | 4 | 9 | 8 |
| Psaumes | 5 | 13 | 12 |
| Psaumes | 6 | 11 | 10 |
| Psaumes | 7 | 18 | 17 |
| Psaumes | 8 | 10 | 9 |
| Psaumes | 9 | 21 | 20 |
| Psaumes | 12 | 9 | 8 |
| Psaumes | 18 | 51 | 50 |
| Psaumes | 19 | 15 | 14 |
| Psaumes | 20 | 10 | 9 |
| Psaumes | 21 | 14 | 13 |
| Psaumes | 22 | 32 | 31 |
| Psaumes | 30 | 13 | 12 |
| Psaumes | 31 | 25 | 24 |
| Psaumes | 34 | 23 | 22 |
| Psaumes | 36 | 13 | 12 |
| Psaumes | 38 | 23 | 22 |
| Psaumes | 39 | 14 | 13 |
| Psaumes | 40 | 18 | 17 |
| Psaumes | 41 | 14 | 13 |
| Psaumes | 42 | 12 | 11 |
| Psaumes | 44 | 27 | 26 |
| Psaumes | 45 | 18 | 17 |
| Psaumes | 46 | 12 | 11 |
| Psaumes | 47 | 10 | 9 |
| Psaumes | 48 | 15 | 14 |
| Psaumes | 49 | 21 | 20 |
| Psaumes | 51 | 21 | 19 |
| Psaumes | 52 | 11 | 9 |
| Psaumes | 53 | 7 | 6 |
| Psaumes | 54 | 9 | 7 |
| Psaumes | 55 | 24 | 23 |
| Psaumes | 56 | 14 | 13 |
| Psaumes | 57 | 12 | 11 |
| Psaumes | 58 | 12 | 11 |
| Psaumes | 59 | 18 | 17 |
| Psaumes | 60 | 14 | 12 |
| Psaumes | 61 | 9 | 8 |
| Psaumes | 62 | 13 | 12 |
| Psaumes | 63 | 12 | 11 |
| Psaumes | 64 | 11 | 10 |
| Psaumes | 65 | 14 | 13 |
| Psaumes | 67 | 8 | 7 |
| Psaumes | 68 | 36 | 35 |
| Psaumes | 69 | 37 | 36 |
| Psaumes | 70 | 6 | 5 |
| Psaumes | 75 | 11 | 10 |
| Psaumes | 76 | 13 | 12 |
| Psaumes | 77 | 21 | 20 |
| Psaumes | 80 | 20 | 19 |
| Psaumes | 81 | 17 | 16 |
| Psaumes | 83 | 19 | 18 |
| Psaumes | 84 | 13 | 12 |
| Psaumes | 85 | 14 | 13 |
| Psaumes | 88 | 19 | 18 |
| Psaumes | 89 | 53 | 52 |
| Psaumes | 92 | 16 | 15 |
| Psaumes | 96 | 14 | 13 |
| Psaumes | 102 | 29 | 28 |
| Psaumes | 108 | 14 | 13 |
| Psaumes | 140 | 14 | 13 |
| Psaumes | 142 | 8 | 7 |
| Ecclésiaste | 11 | 8 | 10 |
| Ecclésiaste | 12 | 16 | 14 |
| Esaïe | 8 | 23 | 22 |
| Esaïe | 9 | 20 | 21 |
| Ezéchiel | 20 | 44 | 49 |
| Ezéchiel | 21 | 37 | 32 |
| Osée | 11 | 11 | 12 |
| Osée | 12 | 15 | 14 |
| Jonas | 1 | 16 | 17 |
| Jonas | 2 | 11 | 10 |
| Michée | 4 | 14 | 13 |
| Michée | 5 | 14 | 15 |
| Marc | 10 | 53 | 52 |
| Jean | 1 | 52 | 51 |
| Actes | 19 | 40 | 41 |
| 2 Corinthiens | 13 | 13 | 14 |
| 3 Jean | 1 | 15 | 14 |
| Révélation | 12 | 18 | 17 |
