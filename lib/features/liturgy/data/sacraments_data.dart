class SacramentInfo {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final IconRef icon;

  const SacramentInfo({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.icon,
  });
}

/// Placeholder enum so this data file doesn't need to import Flutter —
/// the screen maps these to actual IconData.
enum IconRef { baptism, communion, confirmation, marriage, funeral, ordination }

/// General, original descriptions of the sacraments and key rites as
/// practiced in The United Methodist Church. This explains MEANING and
/// STRUCTURE only — not the official liturgical wording (vows, blessings,
/// the Great Thanksgiving, etc.), which belongs to the UMC Book of
/// Worship and should be used directly from that source, alongside the
/// pastor's guidance, when actually conducting these rites.
class SacramentsData {
  static const String introNote =
      "L'Église Méthodiste Unie reconnaît deux sacrements : le baptême et "
      "la Sainte-Cène. Elle célèbre aussi d'autres rites importants dans "
      "la vie de la communauté. Les textes exacts de ces rites (vœux, "
      "prières, bénédictions) se trouvent dans le Livre de Culte officiel "
      "de l'Église Méthodiste Unie ; ce module en présente le sens et la "
      "structure générale.";

  static const List<SacramentInfo> items = [
    SacramentInfo(
      id: 'bapteme',
      name: 'Le Baptême',
      subtitle: 'Sacrement d\'initiation chrétienne',
      icon: IconRef.baptism,
      description:
          "Le baptême marque l'entrée dans la communauté de foi et signe "
          "la grâce de Dieu qui accueille la personne baptisée, enfant ou "
          "adulte, dans l'alliance. L'Église Méthodiste Unie pratique "
          "aussi bien le baptême des enfants — sur la promesse des "
          "parents et de la communauté de l'élever dans la foi — que "
          "celui des adultes qui professent leur foi personnelle.\n\n"
          "Le rite comprend généralement une profession de foi (par la "
          "personne elle-même ou par ses parents et parrains/marraines), "
          "l'engagement de la communauté à soutenir cette personne dans "
          "sa vie chrétienne, puis l'aspersion ou l'immersion d'eau au "
          "nom du Père, du Fils et du Saint-Esprit.\n\n"
          "Le baptême n'est célébré qu'une seule fois dans une vie : il "
          "n'est pas répété, même en cas de changement d'Église.",
    ),
    SacramentInfo(
      id: 'sainte_cene',
      name: 'La Sainte-Cène',
      subtitle: 'Communion, Eucharistie',
      icon: IconRef.communion,
      description:
          "La Sainte-Cène commémore le dernier repas de Jésus avec ses "
          "disciples et son sacrifice sur la croix. Dans la tradition "
          "méthodiste, la table est ouverte : tous ceux qui aiment le "
          "Christ, se repentent de leur péché et cherchent à vivre en "
          "paix avec leur prochain sont invités à y participer, quel que "
          "soit leur âge ou leur Église d'origine.\n\n"
          "Le rite suit généralement une Grande Action de grâce — une "
          "prière qui retrace l'œuvre de Dieu depuis la création jusqu'au "
          "sacrifice du Christ — suivie de la consécration et du partage "
          "du pain et de la coupe.\n\n"
          "Les Églises Méthodistes Unies sont invitées à célébrer la "
          "Sainte-Cène aussi souvent que possible, idéalement chaque "
          "dimanche, et au minimum une fois par mois.",
    ),
    SacramentInfo(
      id: 'confirmation',
      name: 'La Confirmation',
      subtitle: 'Profession publique de la foi',
      icon: IconRef.confirmation,
      description:
          "La confirmation permet à une personne baptisée enfant de "
          "professer personnellement et publiquement la foi dans laquelle "
          "elle a été élevée, et de devenir membre professant de "
          "l'Église. Elle est généralement précédée d'un temps de "
          "formation (catéchisme ou classe de confirmation).\n\n"
          "Ce n'est pas un second baptême, mais la réponse personnelle à "
          "la grâce déjà reçue lors du baptême.",
    ),
    SacramentInfo(
      id: 'mariage',
      name: 'Le Mariage',
      subtitle: 'Célébration de l\'union',
      icon: IconRef.marriage,
      description:
          "Le service de mariage célèbre l'union d'un couple devant Dieu "
          "et la communauté, qui s'engage à les soutenir. Il comprend "
          "traditionnellement des lectures bibliques, l'échange des vœux "
          "et des anneaux, une prière de bénédiction sur le couple, et "
          "se conclut souvent par la présentation du couple à "
          "l'assemblée.",
    ),
    SacramentInfo(
      id: 'funerailles',
      name: 'Le Service funèbre',
      subtitle: 'Culte d\'action de grâces pour une vie',
      icon: IconRef.funeral,
      description:
          "Le service funèbre méthodiste est avant tout un culte "
          "d'action de grâces pour la vie du défunt et une affirmation de "
          "l'espérance de la résurrection. Il comprend généralement des "
          "lectures bibliques sur l'espérance chrétienne, un temps de "
          "témoignage ou d'hommage, la prédication, et une prière de "
          "consolation pour la famille et les proches.",
    ),
  ];

  static SacramentInfo byId(String id) =>
      items.firstWhere((s) => s.id == id);
}
