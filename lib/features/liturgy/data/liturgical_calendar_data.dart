import '../models/liturgical_period.dart';

/// Content for the Christian liturgical calendar, as observed in The United
/// Methodist Church. Written independently for this app (not reproduced
/// from any external publication); general church-calendar knowledge.
class LiturgicalCalendarData {
  static const List<LiturgicalPeriod> periods = [
    LiturgicalPeriod(
      id: 'avent',
      name: 'Avent',
      type: LiturgicalPeriodType.season,
      colorName: 'Violet / Bleu',
      colorHex: 0xFF5E3A8C,
      summary: "Préparation à la venue du Christ",
      description:
          "L'Avent ouvre l'année chrétienne. Son nom vient du latin adventus, "
          "« venue ». Il commence le quatrième dimanche avant Noël, en général "
          "juste après Thanksgiving, et invite à un temps de préparation "
          "spirituelle avant la célébration de la naissance du Christ.\n\n"
          "Chaque dimanche, une bougie de la couronne de l'Avent est allumée : "
          "espérance, paix, joie, puis amour. La veille de Noël, une cinquième "
          "bougie blanche — la bougie du Christ — est allumée au centre.\n\n"
          "Le violet symbolise à la fois la pénitence et la royauté du Roi qui "
          "vient ; le bleu, utilisé dans certaines Églises, évoque l'espérance "
          "et l'attente.",
    ),
    LiturgicalPeriod(
      id: 'noel',
      name: 'Jour de Noël',
      type: LiturgicalPeriodType.holyDay,
      colorName: 'Or / Blanc',
      colorHex: 0xFFD4A017,
      summary: "Naissance de Jésus-Christ",
      description:
          "Le 25 décembre, l'Église célèbre la naissance de Jésus, "
          "l'aboutissement du temps de l'Avent. Suivant la tradition "
          "hébraïque de commencer le jour au coucher du soleil, de nombreuses "
          "Églises Méthodistes Unies célèbrent Noël par un service la veille "
          "au soir plutôt que le jour même, sauf si celui-ci tombe un "
          "dimanche.\n\n"
          "Noël ouvre une période de retrouvailles familiales, de partage et "
          "de joie qui se prolonge dans le temps de Noël.",
    ),
    LiturgicalPeriod(
      id: 'temps_noel',
      name: 'Temps de Noël',
      type: LiturgicalPeriodType.season,
      colorName: 'Or / Blanc',
      colorHex: 0xFFD4A017,
      summary: "Douze jours célébrant la royauté du Christ",
      description:
          "Le temps de Noël dure douze jours, du 25 décembre à la veille de "
          "l'Épiphanie (6 janvier). L'or et le blanc y symbolisent la "
          "royauté et la pureté du Christ.\n\n"
          "Le réveillon du Nouvel An tombe durant cette période ; certaines "
          "communautés Méthodistes Unies organisent une veillée de "
          "consécration. Le 1er janvier, certains observent aussi la fête du "
          "Saint Nom de Jésus, rappelant le jour où l'enfant reçut son nom "
          "selon la tradition juive, huit jours après sa naissance "
          "(Luc 2.21).",
    ),
    LiturgicalPeriod(
      id: 'epiphanie',
      name: 'Épiphanie',
      type: LiturgicalPeriodType.holyDay,
      colorName: 'Vert',
      colorHex: 0xFF2E7D32,
      summary: "La manifestation du Christ au monde",
      description:
          "Célébrée le 6 janvier, l'Épiphanie — du grec « manifestation » — "
          "clôt le temps de Noël. Elle commémore la révélation de Jésus au "
          "monde, aujourd'hui principalement associée à la visite des mages "
          "(Matthieu 2.1-12), mais qui rassemblait historiquement aussi son "
          "baptême et son premier miracle aux noces de Cana : trois moments "
          "où d'autres découvrent qui est Jésus.\n\n"
          "Dans certaines cultures, l'Épiphanie se marque par un repas "
          "festif ou un gâteau des rois, et par la bénédiction des maisons.",
    ),
    LiturgicalPeriod(
      id: 'ordinaire_epiphanie',
      name: 'Temps ordinaire après l\'Épiphanie',
      type: LiturgicalPeriodType.season,
      colorName: 'Vert',
      colorHex: 0xFF2E7D32,
      summary: "Croissance spirituelle avant le Carême",
      description:
          "Cette première période de temps ordinaire s'étend de "
          "l'Épiphanie jusqu'au Carême, généralement de la mi-janvier à la "
          "mi-février ou au début mars. Le vert y symbolise la croissance "
          "et le développement spirituel.\n\n"
          "Loin d'être un temps « creux », elle comprend deux dimanches "
          "marquants : le dimanche du Baptême du Seigneur, la semaine "
          "suivant l'Épiphanie, et le dimanche de la Transfiguration, "
          "dernier dimanche avant le Carême.",
    ),
    LiturgicalPeriod(
      id: 'careme',
      name: 'Carême',
      type: LiturgicalPeriodType.season,
      colorName: 'Violet (Rouge en Semaine sainte)',
      colorHex: 0xFF5E3A8C,
      summary: "40 jours de préparation vers Pâques",
      description:
          "Le Carême s'ouvre le Mercredi des Cendres et dure 40 jours (hors "
          "dimanches) jusqu'à Pâques. C'est un temps de repentance, "
          "d'examen intérieur et de préparation spirituelle, vécu par la "
          "prière, le jeûne, le service et le culte.\n\n"
          "Lors du service du Mercredi des Cendres, une croix de cendres "
          "est imposée sur le front — signe de mortalité et de pénitence, "
          "rappelant le besoin de la grâce de Dieu. La dernière semaine, "
          "dite Semaine sainte, comprend le Dimanche des Rameaux, le Jeudi "
          "saint et le Vendredi saint, qui commémorent la passion et la "
          "mort de Jésus. Le violet, couleur de la pénitence, cède la "
          "place au rouge pendant la Semaine sainte, en mémoire du "
          "sacrifice du Christ.",
    ),
    LiturgicalPeriod(
      id: 'paques',
      name: 'Dimanche de Pâques',
      type: LiturgicalPeriodType.holyDay,
      colorName: 'Blanc',
      colorHex: 0xFFFFFFFF,
      summary: "La résurrection du Christ",
      description:
          "Pâques est le jour le plus important de l'année chrétienne : la "
          "résurrection du Christ. Sa date — le premier dimanche après la "
          "première pleine lune suivant l'équinoxe de printemps — "
          "détermine celle du Carême et de la Pentecôte.\n\n"
          "Pâques symbolise la vie nouvelle et la victoire sur la mort. Les "
          "Méthodistes Unis célèbrent généralement la Sainte-Cène, chantent "
          "des hymnes de la résurrection — dont « Le Christ est ressuscité » "
          "de Charles Wesley — et ornent les sanctuaires de lys de Pâques. "
          "Le blanc, couleur de la pureté et de la joie, domine ce jour.",
    ),
    LiturgicalPeriod(
      id: 'temps_paques',
      name: 'Temps de Pâques',
      type: LiturgicalPeriodType.season,
      colorName: 'Blanc / Or',
      colorHex: 0xFFD4A017,
      summary: "50 jours de joie jusqu'à la Pentecôte",
      description:
          "Le temps de Pâques s'étend sur 50 jours, du dimanche de Pâques "
          "jusqu'à la Pentecôte. Le blanc et l'or y célèbrent la "
          "résurrection, la royauté et la gloire — un temps joyeux, à "
          "l'opposé du recueillement du Carême.\n\n"
          "C'est aussi une période propice à la formation spirituelle : "
          "cours de théologie, préparation au discipulat, et souvent le "
          "dimanche de la Confirmation, où de jeunes croyants professent "
          "publiquement leur foi. Le temps de Pâques inclut également le "
          "Jour de l'Ascension, 40 jours après Pâques, marquant le retour "
          "de Jésus auprès du Père — célébré par la plupart des Églises le "
          "dimanche suivant.",
    ),
    LiturgicalPeriod(
      id: 'pentecote',
      name: 'Dimanche de Pentecôte',
      type: LiturgicalPeriodType.holyDay,
      colorName: 'Rouge',
      colorHex: 0xFFE4002B,
      summary: "La naissance de l'Église",
      description:
          "La Pentecôte — du grec « cinquantième » — tombe le huitième "
          "dimanche après Pâques. Elle célèbre la descente du Saint-Esprit "
          "sur les apôtres, qui purent alors s'exprimer en plusieurs "
          "langues (Actes 2). On y voit souvent la naissance de l'Église.\n\n"
          "Le rouge, couleur du feu de l'Esprit, est porté par le clergé et "
          "les fidèles. La Pentecôte est l'occasion de réaffirmer la "
          "mission de faire de toutes les nations des disciples "
          "(Matthieu 28.19-20) et de célébrer l'unité dans la diversité — "
          "chants et prières résonnant parfois en plusieurs langues.",
    ),
    LiturgicalPeriod(
      id: 'ordinaire_pentecote',
      name: 'Temps ordinaire après la Pentecôte',
      type: LiturgicalPeriodType.season,
      colorName: 'Vert',
      colorHex: 0xFF2E7D32,
      summary: "La plus longue saison de l'année chrétienne",
      description:
          "Cette dernière et plus longue saison couvre la majeure partie "
          "de l'été et de l'automne, de la Pentecôte jusqu'au dimanche "
          "précédant l'Avent suivant. Le vert y symbolise, à nouveau, la "
          "croissance et la vie.\n\n"
          "Malgré son nom, elle est riche en célébrations : le dimanche de "
          "la Trinité (premier dimanche après la Pentecôte), la Toussaint "
          "(1er novembre), et le dimanche du Christ-Roi, qui clôt l'année "
          "chrétienne juste avant que l'Avent ne recommence le cycle. "
          "Écoles bibliques de vacances, voyages missionnaires et camps "
          "d'été rythment souvent cette saison.",
    ),
  ];

  static LiturgicalPeriod byId(String id) =>
      periods.firstWhere((p) => p.id == id);
}
