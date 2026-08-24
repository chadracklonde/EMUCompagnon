class WorshipStep {
  final String title;
  final String description;

  const WorshipStep({required this.title, required this.description});
}

/// General structure of a Sunday service as typically practiced in United
/// Methodist congregations. This describes the customary FLOW and PURPOSE
/// of each moment — it is not a verbatim liturgical text. Official prayer
/// wording, vows, and blessings belong to the UMC Book of Worship and
/// should be used directly from that source when leading worship.
class WorshipOrderData {
  static const String introNote =
      "Cet ordre du culte présente la structure habituelle d'un service "
      "dominical méthodiste uni — un repère, pas un texte figé : l'ordre "
      "exact, les prières et les paroles précises varient d'une "
      "congrégation à l'autre et relèvent du Livre de Culte officiel de "
      "l'Église Méthodiste Unie (UM Book of Worship) et du pasteur "
      "responsable.";

  static const List<WorshipStep> steps = [
    WorshipStep(
      title: 'Accueil et annonces',
      description:
          "La communauté se rassemble. Les annonces de la vie paroissiale "
          "sont partagées avant que le culte proprement dit ne commence.",
    ),
    WorshipStep(
      title: 'Appel au culte',
      description:
          "Une parole d'ouverture, souvent tirée des Psaumes, invite "
          "l'assemblée à tourner son cœur vers Dieu et marque le début "
          "du temps de culte.",
    ),
    WorshipStep(
      title: 'Cantique d\'ouverture',
      description:
          "Un chant de louange rassemble les voix de la communauté dans "
          "un même élan d'adoration.",
    ),
    WorshipStep(
      title: 'Prière d\'invocation',
      description:
          "Le culte est confié à Dieu ; on demande la présence et la "
          "conduite du Saint-Esprit pour le temps qui s'ouvre.",
    ),
    WorshipStep(
      title: 'Prière de confession et pardon',
      description:
          "Un temps de repentance collective, suivi de l'assurance du "
          "pardon offert en Christ — souvent accompagné d'un signe de "
          "paix échangé entre les fidèles.",
    ),
    WorshipStep(
      title: 'Lectures bibliques',
      description:
          "Un ou plusieurs passages sont lus, souvent tirés de l'Ancien "
          "Testament, des Psaumes, des Épîtres et des Évangiles, parfois "
          "selon le cycle du lectionnaire.",
    ),
    WorshipStep(
      title: 'Cantique de préparation',
      description:
          "Un chant prépare les cœurs à recevoir la prédication qui suit.",
    ),
    WorshipStep(
      title: 'Prédication',
      description:
          "Le pasteur ou le prédicateur proclame et explique la Parole de "
          "Dieu à partir des textes lus, pour édifier et interpeller "
          "l'assemblée.",
    ),
    WorshipStep(
      title: 'Réponse à la Parole',
      description:
          "Par un cantique, un temps de silence ou une invitation à la "
          "consécration, l'assemblée répond à ce qui vient d'être "
          "entendu.",
    ),
    WorshipStep(
      title: 'Offrande',
      description:
          "La communauté apporte ses dons en signe de gratitude et de "
          "participation à la mission de l'Église, souvent accompagnée "
          "d'un chant ou d'une prière de dédicace.",
    ),
    WorshipStep(
      title: 'Sainte-Cène (si célébrée)',
      description:
          "Lorsque la Cène est célébrée — traditionnellement au moins une "
          "fois par mois dans les Églises Méthodistes Unies — la Grande "
          "Action de grâce et le partage du pain et de la coupe suivent, "
          "selon les textes du Livre de Culte.",
    ),
    WorshipStep(
      title: 'Prières d\'intercession',
      description:
          "La communauté prie pour l'Église, le monde, les malades et "
          "ceux qui souffrent, et pour ses propres besoins.",
    ),
    WorshipStep(
      title: 'Cantique d\'envoi',
      description:
          "Un dernier chant accompagne la communauté vers l'envoi en "
          "mission.",
    ),
    WorshipStep(
      title: 'Bénédiction et envoi',
      description:
          "Le pasteur bénit l'assemblée et l'envoie vivre sa foi dans le "
          "monde jusqu'au prochain rassemblement.",
    ),
  ];
}
