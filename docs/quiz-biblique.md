# Quiz biblique

Écran « Plus › Vie spirituelle › Quiz biblique » : dix questions tirées au hasard dans une banque de **3 327 questions en français**, avec choix du Testament et de la difficulté, retour immédiat (bonne réponse, référence Louis Segond quand il y en a une), score et meilleur score. Tout fonctionne hors connexion.

## Données

- Fichier : `assets/quiz/quiz_fr.json` (format compact : `id`, `t` question, `o` options, `a` index de la bonne réponse, `c` catégorie, `n` niveau 1 à 3, `b` AT/NT, `r` références).
- Texte biblique de référence : **Louis Segond 1910** (celui de l'application).
- Les questions viennent de banques anglaises traduites, puis corrigées et reformulées en français (lots 1 à 17 du projet de révision). Les doublons d'énoncé sont conservés volontairement.
- `catégorie`, `niveau` et `testament` sont des **propositions automatiques**, non relues.
- `docs/quiz-questions-sensibles.csv` : questions touchant à la violence, à la sexualité, à des pratiques propres à certaines Églises ou à des doctrines disputées, à relire avant publication.

## À régler avant toute publication

1. **Droits sur les questions.** L'origine des banques anglaises et l'autorisation de les reprendre n'ont pas été établies. La Louis Segond est dans le domaine public, pas forcément les questions. Ne pas publier tant que ce point n'est pas clarifié.
2. **Relecture par une personne de l'Église** des questions sensibles (fichier ci-dessus) et d'un échantillon de réponses : seule une partie de la banque a été relue question par question.
3. **Kiswahili.** Les textes de l'interface sont traduits sans relecture par un locuteur natif. Les questions restent en français.

## Mémoire locale

`SharedPreferences` : liste des 600 dernières questions vues (pour éviter les répétitions), nombre de parties et meilleur score. Rien n'est envoyé hors de l'appareil.
