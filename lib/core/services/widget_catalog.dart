/// The widgets of the Android home screen, as listed on the "Widgets"
/// screen. Keep in step with native/android/widgets.json (a test checks it).
class WidgetInfo {
  final String key;
  final String label;
  final String description;
  final String family;
  const WidgetInfo(this.key, this.label, this.description, this.family);
}

class WidgetCatalog {
  static const families = ['Lecture', 'Liturgie', 'Cantiques', 'Vie spirituelle', 'Raccourcis'];

  static const all = <WidgetInfo>[
    WidgetInfo('verse', 'Verset du jour', 'Le verset du jour de ÉMU Compagnon', 'Lecture'),
    WidgetInfo('reading_plan', 'Lecture du jour', 'Le passage à lire aujourd\'hui et la progression de votre plan', 'Lecture'),
    WidgetInfo('season', 'Saison liturgique', 'La saison de l\'année chrétienne en cours, avec sa couleur', 'Liturgie'),
    WidgetInfo('color', 'Couleur du jour', 'La couleur liturgique du moment', 'Liturgie'),
    WidgetInfo('next_sunday', 'Prochain dimanche', 'La date, la saison et la couleur du prochain dimanche', 'Liturgie'),
    WidgetInfo('countdown', 'Compte à rebours', 'Les jours qui restent avant le prochain temps fort de l\'année chrétienne', 'Liturgie'),
    WidgetInfo('calendar', 'Calendrier liturgique', 'Les prochains temps forts de l\'année chrétienne', 'Liturgie'),
    WidgetInfo('worship_hymns', 'Cantiques du culte', 'Les cantiques de la liste choisie pour le culte', 'Cantiques'),
    WidgetInfo('streak', 'Série de jours', 'Le nombre de jours consécutifs où vous avez ouvert l\'application', 'Vie spirituelle'),
    WidgetInfo('week', 'Semaine de lecture', 'Les jours de la semaine où vous avez ouvert l\'application', 'Vie spirituelle'),
    WidgetInfo('memorize', 'Verset à mémoriser', 'Le verset à réviser aujourd\'hui', 'Lecture'),
    WidgetInfo('shortcuts', 'Raccourcis', 'Rechercher, Bible, Cantiques et Culte en un geste', 'Raccourcis'),
    WidgetInfo('pinned_text', 'Prière épinglée', 'Le texte que vous avez épinglé (le Notre Père par défaut)', 'Cantiques'),
    WidgetInfo('hymn_of_day', 'Cantique du jour', 'Un cantique différent chaque jour', 'Cantiques'),
    WidgetInfo('resume_bible', 'Reprendre la Bible', 'Le dernier chapitre lu, à rouvrir en un geste', 'Lecture'),
    WidgetInfo('resume_hymn', 'Reprendre le cantique', 'Le dernier cantique ouvert', 'Cantiques'),
    WidgetInfo('favorites', 'Mes favoris', 'Un de vos versets ou cantiques favoris, différent chaque jour', 'Lecture'),
    WidgetInfo('challenge', 'Défi de la semaine', 'Le défi spirituel de la semaine', 'Vie spirituelle'),
    WidgetInfo('quiz', 'Quiz du jour', 'Votre quiz biblique du jour', 'Vie spirituelle'),
    WidgetInfo('examen', 'Examen du soir', 'Un rappel pour relire votre journée devant Dieu', 'Vie spirituelle'),
    WidgetInfo('journal', 'Écrire une prière', 'Ouvre le journal de prière', 'Vie spirituelle'),
    WidgetInfo('word', 'Mot du jour', 'Un terme du dictionnaire biblique, différent chaque jour', 'Lecture'),
    WidgetInfo('search', 'Recherche', 'Ouvre la recherche dans toute l\'application', 'Raccourcis'),
  ];

  static List<WidgetInfo> inFamily(String family) =>
      [for (final w in all) if (w.family == family) w];
}
