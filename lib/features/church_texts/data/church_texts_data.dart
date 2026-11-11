import '../models/church_text.dart';

/// Prayers and texts of The United Methodist Church shown under
/// "Prières et textes".
///
/// Sources:
///  * the Lord's Prayer is the text of the app's Bible (Louis Segond 1910);
///  * the Social Creed follows the French version supplied by the project
///    owner;
///  * the other texts come from a machine translation of The Book of
///    Discipline 2020/2024, corrected by hand where the translation was
///    plainly wrong. They are to be proofread by the project owner — keep
///    any correction here, in this one file.
class ChurchTextsData {
  static const _discipline = 'Livre de Discipline de l\'Église Méthodiste Unie, 2020/2024';

  static const List<ChurchTextGroup> groups = [
    ChurchTextGroup('Prières', [lordsPrayer, socialCreed, socialCreedLitany]),
    ChurchTextGroup('Ce que nous croyons', [articlesOfReligion, confessionOfFaith]),
    ChurchTextGroup('Vivre en disciple', [generalRules, membershipVows, mission]),
  ];

  static ChurchText? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  static List<ChurchText> get all => [for (final g in groups) ...g.texts];

  static const lordsPrayer = ChurchText(
    id: 'notre_pere',
    title: 'Le Notre Père',
    subtitle: 'La prière enseignée par Jésus',
    icon: ChurchTextIcon.prayer,
    source: 'Matthieu 6.9-13, Louis Segond 1910',
    blocks: [
      TextBlock.p('Notre Père qui es aux cieux !'),
      TextBlock.p('Que ton nom soit sanctifié ;'),
      TextBlock.p('que ton règne vienne ;'),
      TextBlock.p('que ta volonté soit faite sur la terre comme au ciel.'),
      TextBlock.p('Donne-nous aujourd\'hui notre pain quotidien ;'),
      TextBlock.p(
        'pardonne-nous nos offenses, comme nous aussi nous pardonnons à '
        'ceux qui nous ont offensés ;',
      ),
      TextBlock.p('ne nous induis pas en tentation, mais délivre-nous du malin.'),
      TextBlock.p(
        'Car c\'est à toi qu\'appartiennent, dans tous les siècles, le '
        'règne, la puissance et la gloire.',
      ),
      TextBlock.p('Amen !'),
    ],
  );

  static const socialCreed = ChurchText(
    id: 'credo_social',
    title: 'Le Credo social',
    subtitle: 'Notre foi vécue dans le monde',
    icon: ChurchTextIcon.creed,
    source: 'Credo social de l\'Église Méthodiste Unie (Livre de Discipline, ¶ 164)',
    blocks: [
      TextBlock.p(
        'Nous croyons en Dieu, le créateur du monde, et en Jésus-Christ, le '
        'sauveur de toute créature. Nous croyons au Saint-Esprit qui nous '
        'fait connaître les dons de Dieu.',
      ),
      TextBlock.p(
        'Nous reconnaissons avoir souvent mésusé de ces dons à des fins '
        'idolâtres et regrettons notre faute.',
      ),
      TextBlock.p(
        'Nous affirmons que la nature est l\'œuvre de Dieu et nous nous '
        'consacrons à la préserver, à l\'entretenir et à faire en sorte que '
        'l\'humanité l\'utilise de manière responsable.',
      ),
      TextBlock.p(
        'Nous recevons avec joie, pour nous-mêmes et pour les autres, les '
        'bénédictions que sont la communauté, la sexualité, le mariage et '
        'la famille.',
      ),
      TextBlock.p(
        'Nous nous engageons en faveur des droits des hommes et des femmes '
        '– enfants, adolescents, jeunes adultes, aînés et personnes avec un '
        'handicap ; en faveur de l\'amélioration de la qualité de vie ; et '
        'en faveur des droits et de la dignité de tous les êtres humains.',
      ),
      TextBlock.p(
        'Nous croyons au droit et au devoir de toute personne d\'œuvrer '
        'pour la gloire de Dieu, en vue de son bien et de celui des autres, '
        'et par là d\'assurer son bien-être ; aux droits à la propriété '
        'dans la mesure où elle nous est confiée par Dieu, à la négociation '
        'collective, à une consommation responsable ; et à l\'élimination '
        'de la misère économique et sociale.',
      ),
      TextBlock.p(
        'Nous nous consacrons à la paix dans le monde, au règne de la '
        'justice et de la loi parmi les nations et à la liberté '
        'individuelle pour tous les habitants de la terre.',
      ),
      TextBlock.p(
        'Nous croyons en la victoire présente et définitive de la Parole de '
        'Dieu dans les affaires humaines et acceptons avec joie notre '
        'mission de vivre l\'Évangile dans le monde.',
      ),
      TextBlock.p('Amen.'),
    ],
  );

  static const socialCreedLitany = ChurchText(
    id: 'litanie_credo_social',
    title: 'Litanie du Credo social',
    subtitle: 'À dire ensemble pendant le culte',
    icon: ChurchTextIcon.litany,
    source: '$_discipline, ¶ 164',
    blocks: [
      TextBlock.leader(
        'Dieu, dans l\'Esprit révélé en Jésus-Christ, nous appelle par '
        'grâce à être renouvelés à l\'image de notre Créateur, afin que '
        'nous soyons un dans l\'amour divin pour le monde.',
      ),
      TextBlock.leader(
        'Aujourd\'hui est le jour où Dieu prend soin de l\'intégrité de la '
        'création, veut la guérison et la plénitude de toute vie, et pleure '
        'le pillage des richesses de la terre.',
      ),
      TextBlock.people('Et nous aussi.'),
      TextBlock.leader(
        'Aujourd\'hui est le jour où Dieu embrasse toutes les couleurs de '
        'l\'humanité, se réjouit de la diversité et de la différence, et '
        'favorise la solidarité qui fait des étrangers des amis.',
      ),
      TextBlock.people('Et nous aussi.'),
      TextBlock.leader(
        'Aujourd\'hui est le jour où Dieu pleure avec les foules affamées, '
        'réprouve l\'écart grandissant entre riches et pauvres, et exige la '
        'justice pour les travailleurs.',
      ),
      TextBlock.people('Et nous aussi.'),
      TextBlock.leader(
        'Aujourd\'hui est le jour où Dieu déplore la violence dans nos '
        'foyers et dans nos rues, condamne la folie guerrière du monde, '
        'abaisse les puissants et élève les humbles.',
      ),
      TextBlock.people('Et nous aussi.'),
      TextBlock.leader(
        'Aujourd\'hui est le jour où Dieu appelle les nations et les '
        'peuples à vivre en paix, célèbre le lieu où la justice et la '
        'miséricorde s\'embrassent, et exulte quand le loup paît avec '
        'l\'agneau.',
      ),
      TextBlock.people('Et nous aussi.'),
      TextBlock.leader(
        'Aujourd\'hui est le jour où Dieu apporte la bonne nouvelle aux '
        'pauvres, proclame la délivrance aux captifs, rend la vue aux '
        'aveugles et libère les opprimés.',
      ),
      TextBlock.people('Et nous aussi.'),
    ],
  );

  static const articlesOfReligion = ChurchText(
    id: 'articles_de_religion',
    title: 'Les Articles de religion',
    subtitle: 'Les 25 articles de l\'Église méthodiste',
    icon: ChurchTextIcon.articles,
    source: '$_discipline, ¶ 104',
    blocks: [
      TextBlock.note(
        'Ces articles reprennent le texte de la Discipline de 1808, que '
        'John Wesley avait tiré en 1784 des Trente-neuf articles de '
        'l\'Église d\'Angleterre. Leur langage est celui de leur époque.',
      ),
      TextBlock.heading('Article I — De la foi en la Sainte Trinité'),
      TextBlock.p(
        'Il n\'y a qu\'un seul Dieu vivant et vrai, éternel, sans corps ni '
        'parties, d\'une puissance, d\'une sagesse et d\'une bonté '
        'infinies, créateur et conservateur de toutes choses, visibles et '
        'invisibles. Et dans l\'unité de cette divinité, il y a trois '
        'personnes, d\'une même substance, d\'une même puissance et d\'une '
        'même éternité : le Père, le Fils et le Saint-Esprit.',
      ),
      TextBlock.heading('Article II — Du Verbe, ou Fils de Dieu, qui s\'est fait homme'),
      TextBlock.p(
        'Le Fils, qui est le Verbe du Père, le Dieu véritable et éternel, '
        'd\'une seule substance avec le Père, a pris la nature humaine dans '
        'le sein de la bienheureuse Vierge, de sorte que deux natures '
        'entières et parfaites, c\'est-à-dire la divinité et l\'humanité, '
        'ont été unies en une seule personne, pour ne jamais être '
        'divisées ; d\'où il n\'y a qu\'un seul Christ, vrai Dieu et vrai '
        'homme, qui a vraiment souffert, a été crucifié, est mort et a été '
        'enseveli, pour réconcilier son Père avec nous, et pour être un '
        'sacrifice, non seulement pour la faute originelle, mais encore '
        'pour les péchés actuels des hommes.',
      ),
      TextBlock.heading('Article III — De la résurrection du Christ'),
      TextBlock.p(
        'Le Christ est véritablement ressuscité des morts et a repris son '
        'corps, avec tout ce qui appartient à la perfection de la nature '
        'humaine, avec lequel il est monté au ciel, et là il siège jusqu\'à '
        'ce qu\'il revienne pour juger tous les hommes au dernier jour.',
      ),
      TextBlock.heading('Article IV — Du Saint-Esprit'),
      TextBlock.p(
        'Le Saint-Esprit, procédant du Père et du Fils, est d\'une seule '
        'substance, d\'une seule majesté et d\'une seule gloire avec le '
        'Père et le Fils, Dieu véritable et éternel.',
      ),
      TextBlock.heading('Article V — De la suffisance des Saintes Écritures pour le salut'),
      TextBlock.p(
        'L\'Écriture sainte contient tout ce qui est nécessaire au salut ; '
        'de sorte que tout ce qui n\'y est pas lu, ou qui ne peut être '
        'prouvé par elle, ne doit être exigé de personne comme article de '
        'foi, ni être tenu pour requis ou nécessaire au salut. Par '
        'l\'Écriture sainte, nous entendons les livres canoniques de '
        'l\'Ancien et du Nouveau Testament dont l\'autorité n\'a jamais été '
        'mise en doute dans l\'Église. Les noms des livres canoniques '
        'sont :',
      ),
      TextBlock.p(
        'Genèse, Exode, Lévitique, Nombres, Deutéronome, Josué, Juges, '
        'Ruth, le premier livre de Samuel, le deuxième livre de Samuel, le '
        'premier livre des Rois, le deuxième livre des Rois, le premier '
        'livre des Chroniques, le deuxième livre des Chroniques, le livre '
        'd\'Esdras, le livre de Néhémie, le livre d\'Esther, le livre de '
        'Job, les Psaumes, les Proverbes, l\'Ecclésiaste ou le Prédicateur, '
        'le Cantique des cantiques de Salomon, les quatre grands prophètes, '
        'les douze petits prophètes.',
      ),
      TextBlock.p(
        'Tous les livres du Nouveau Testament, tels qu\'ils sont '
        'communément reçus, nous les recevons et les tenons pour '
        'canoniques.',
      ),
      TextBlock.heading('Article VI — De l\'Ancien Testament'),
      TextBlock.p(
        'L\'Ancien Testament n\'est pas contraire au Nouveau ; car dans '
        'l\'Ancien comme dans le Nouveau Testament, la vie éternelle est '
        'offerte aux hommes par le Christ, qui est le seul médiateur entre '
        'Dieu et les hommes, étant à la fois Dieu et homme. C\'est pourquoi '
        'il ne faut pas écouter ceux qui prétendent que les anciens pères '
        'n\'attendaient que des promesses passagères. Bien que la loi '
        'donnée par Dieu à Moïse, pour ce qui touche aux cérémonies et aux '
        'rites, ne lie pas les chrétiens, et que ses préceptes civils ne '
        'doivent pas nécessairement être reçus dans un État, néanmoins '
        'aucun chrétien, quel qu\'il soit, n\'est dispensé d\'obéir aux '
        'commandements que l\'on appelle moraux.',
      ),
      TextBlock.heading('Article VII — Du péché originel ou de naissance'),
      TextBlock.p(
        'Le péché originel ne consiste pas à imiter Adam (comme le disent '
        'vainement les pélagiens), mais il est la corruption de la nature '
        'de tout homme, naturellement engendré de la descendance d\'Adam, '
        'par laquelle l\'homme est très éloigné de la justice originelle '
        'et, de par sa propre nature, enclin au mal, et cela '
        'continuellement.',
      ),
      TextBlock.heading('Article VIII — Du libre arbitre'),
      TextBlock.p(
        'La condition de l\'homme après la chute d\'Adam est telle qu\'il '
        'ne peut se tourner ni se préparer, par sa propre force naturelle '
        'et par ses œuvres, à la foi et à l\'invocation de Dieu ; c\'est '
        'pourquoi nous n\'avons pas le pouvoir de faire de bonnes œuvres, '
        'agréables et acceptables à Dieu, sans que la grâce de Dieu par le '
        'Christ nous prévienne, afin que nous ayons une bonne volonté, et '
        'travaille avec nous lorsque nous avons cette bonne volonté.',
      ),
      TextBlock.heading('Article IX — De la justification de l\'homme'),
      TextBlock.p(
        'Nous sommes tenus pour justes devant Dieu uniquement à cause du '
        'mérite de notre Seigneur et Sauveur Jésus-Christ, par la foi, et '
        'non à cause de nos propres œuvres ou de nos mérites. C\'est '
        'pourquoi la justification par la foi seule est une doctrine très '
        'salutaire et pleine de réconfort.',
      ),
      TextBlock.heading('Article X — Des bonnes œuvres'),
      TextBlock.p(
        'Bien que les bonnes œuvres, qui sont les fruits de la foi et '
        'suivent la justification, ne puissent effacer nos péchés ni '
        'supporter la sévérité du jugement de Dieu, elles sont néanmoins '
        'agréables et acceptables à Dieu en Christ, et découlent d\'une foi '
        'vraie et vivante, à tel point que par elles une foi vivante peut '
        'être reconnue aussi clairement qu\'un arbre se reconnaît à son '
        'fruit.',
      ),
      TextBlock.heading('Article XI — Des œuvres surérogatoires'),
      TextBlock.p(
        'Les œuvres volontaires, faites en plus et au-delà des '
        'commandements de Dieu, que l\'on appelle œuvres de surérogation, '
        'ne peuvent être enseignées sans arrogance et impiété. Car par '
        'elles les hommes déclarent qu\'ils ne rendent pas seulement à Dieu '
        'tout ce qu\'ils sont tenus de faire, mais qu\'ils font pour lui '
        'plus que ce que le devoir exige ; alors que le Christ dit '
        'clairement : « Quand vous avez fait tout ce qui vous a été '
        'ordonné, dites : Nous sommes des serviteurs inutiles. »',
      ),
      TextBlock.heading('Article XII — Du péché après la justification'),
      TextBlock.p(
        'Tout péché commis volontairement après la justification n\'est '
        'pas le péché contre le Saint-Esprit, ni impardonnable. C\'est '
        'pourquoi il ne faut pas refuser la grâce de la repentance à ceux '
        'qui tombent dans le péché après la justification. Après avoir '
        'reçu le Saint-Esprit, nous pouvons nous éloigner de la grâce '
        'donnée et tomber dans le péché, puis, par la grâce de Dieu, nous '
        'relever et amender notre vie. Il faut donc condamner ceux qui '
        'disent qu\'ils ne peuvent plus pécher tant qu\'ils vivent '
        'ici-bas, ou qui refusent le pardon à ceux qui se repentent '
        'vraiment.',
      ),
      TextBlock.heading('Article XIII — De l\'Église'),
      TextBlock.p(
        'L\'Église visible du Christ est une assemblée de fidèles dans '
        'laquelle la pure Parole de Dieu est prêchée et les sacrements '
        'dûment administrés selon l\'ordonnance du Christ, dans tout ce '
        'qui leur est nécessairement requis.',
      ),
      TextBlock.heading('Article XIV — Du purgatoire'),
      TextBlock.p(
        'La doctrine romaine concernant le purgatoire, les indulgences, le '
        'culte et l\'adoration, tant des images que des reliques, ainsi '
        'que l\'invocation des saints, est une chose vaine, inventée sans '
        'raison, qui ne se fonde sur aucun témoignage de l\'Écriture, mais '
        'qui est contraire à la Parole de Dieu.',
      ),
      TextBlock.heading(
        'Article XV — De l\'usage, dans l\'assemblée, d\'une langue que le peuple comprend',
      ),
      TextBlock.p(
        'Il est manifestement contraire à la Parole de Dieu et à la '
        'coutume de l\'Église primitive de faire la prière publique dans '
        'l\'église, ou d\'administrer les sacrements, dans une langue que '
        'le peuple ne comprend pas.',
      ),
      TextBlock.heading('Article XVI — Des sacrements'),
      TextBlock.p(
        'Les sacrements institués par le Christ ne sont pas seulement des '
        'insignes ou des marques de la profession de foi des chrétiens ; '
        'ils sont plutôt des signes certains de la grâce et de la '
        'bienveillance de Dieu envers nous, par lesquels il agit '
        'invisiblement en nous, et non seulement vivifie, mais aussi '
        'fortifie et confirme notre foi en lui.',
      ),
      TextBlock.p(
        'Il y a deux sacrements institués par le Christ notre Seigneur '
        'dans l\'Évangile, à savoir le baptême et la Cène du Seigneur.',
      ),
      TextBlock.p(
        'Les cinq que l\'on appelle communément sacrements, à savoir la '
        'confirmation, la pénitence, l\'ordre, le mariage et '
        'l\'extrême-onction, ne doivent pas être comptés parmi les '
        'sacrements de l\'Évangile ; ils proviennent en partie d\'une '
        'imitation corrompue des apôtres, et sont en partie des états de '
        'vie approuvés par les Écritures, mais ils n\'ont pas la même '
        'nature que le baptême et la Cène du Seigneur, parce qu\'ils n\'ont '
        'aucun signe visible ni aucune cérémonie institués par Dieu.',
      ),
      TextBlock.p(
        'Les sacrements n\'ont pas été institués par le Christ pour être '
        'contemplés ou portés en procession, mais pour que nous en fassions '
        'un bon usage. Et c\'est seulement en ceux qui les reçoivent '
        'dignement qu\'ils ont un effet salutaire ; mais ceux qui les '
        'reçoivent indignement s\'attirent la condamnation, comme le dit '
        'saint Paul.',
      ),
      TextBlock.heading('Article XVII — Du baptême'),
      TextBlock.p(
        'Le baptême n\'est pas seulement un signe de profession et une '
        'marque de différence par laquelle les chrétiens se distinguent de '
        'ceux qui ne sont pas baptisés ; il est aussi un signe de '
        'régénération ou de nouvelle naissance. Le baptême des jeunes '
        'enfants doit être maintenu dans l\'Église.',
      ),
      TextBlock.heading('Article XVIII — De la Cène du Seigneur'),
      TextBlock.p(
        'La Cène du Seigneur n\'est pas seulement un signe de l\'amour que '
        'les chrétiens doivent avoir les uns pour les autres ; elle est '
        'plutôt un sacrement de notre rédemption par la mort du Christ ; '
        'en sorte que, pour ceux qui la reçoivent comme il convient, '
        'dignement et avec foi, le pain que nous rompons est une '
        'participation au corps du Christ, et de même la coupe de '
        'bénédiction est une participation au sang du Christ.',
      ),
      TextBlock.p(
        'La transsubstantiation, ou le changement de la substance du pain '
        'et du vin dans la Cène de notre Seigneur, ne peut être prouvée par '
        'l\'Écriture sainte ; elle est contraire aux paroles claires de '
        'l\'Écriture, renverse la nature d\'un sacrement et a donné lieu à '
        'de nombreuses superstitions.',
      ),
      TextBlock.p(
        'Le corps du Christ est donné, pris et mangé dans la Cène, '
        'seulement d\'une manière céleste et spirituelle. Et le moyen par '
        'lequel le corps du Christ est reçu et mangé dans la Cène, c\'est '
        'la foi.',
      ),
      TextBlock.p(
        'Le sacrement de la Cène du Seigneur n\'a pas été, par '
        'l\'ordonnance du Christ, conservé, porté en procession, élevé ni '
        'adoré.',
      ),
      TextBlock.heading('Article XIX — Des deux espèces'),
      TextBlock.p(
        'La coupe du Seigneur ne doit pas être refusée aux laïcs ; car les '
        'deux parties de la Cène du Seigneur, selon l\'ordonnance et le '
        'commandement du Christ, doivent être administrées à tous les '
        'chrétiens de la même manière.',
      ),
      TextBlock.heading(
        'Article XX — De l\'unique oblation du Christ, accomplie sur la croix',
      ),
      TextBlock.p(
        'L\'offrande du Christ, faite une fois pour toutes, est la '
        'rédemption, la propitiation et la satisfaction parfaites pour '
        'tous les péchés du monde entier, tant originel qu\'actuels ; et '
        'il n\'y a pas d\'autre satisfaction pour le péché que celle-là '
        'seule. C\'est pourquoi le sacrifice des messes, dans lequel on dit '
        'communément que le prêtre offre le Christ pour les vivants et les '
        'morts, afin d\'obtenir la rémission de la peine ou de la faute, '
        'est une fable blasphématoire et une tromperie dangereuse.',
      ),
      TextBlock.heading('Article XXI — Du mariage des ministres'),
      TextBlock.p(
        'La loi de Dieu ne commande pas aux ministres du Christ de faire '
        'vœu de célibat ni de s\'abstenir du mariage ; il leur est donc '
        'permis, comme à tous les autres chrétiens, de se marier selon '
        'leur propre jugement, comme ils l\'estimeront le plus favorable à '
        'la piété.',
      ),
      TextBlock.heading('Article XXII — Des rites et des cérémonies des Églises'),
      TextBlock.p(
        'Il n\'est pas nécessaire que les rites et les cérémonies soient '
        'partout les mêmes ou exactement semblables ; car ils ont toujours '
        'été différents et peuvent être modifiés selon la diversité des '
        'pays, des temps et des mœurs, pourvu que rien ne soit ordonné '
        'contre la Parole de Dieu. Quiconque, par son jugement personnel, '
        'viole volontairement et délibérément les rites et les cérémonies '
        'de l\'Église à laquelle il appartient, qui ne sont pas contraires '
        'à la Parole de Dieu et qui sont ordonnés et approuvés par '
        'l\'autorité commune, doit être repris ouvertement, afin que '
        'd\'autres craignent d\'en faire autant, comme quelqu\'un qui '
        'offense l\'ordre commun de l\'Église et blesse la conscience des '
        'frères faibles.',
      ),
      TextBlock.p(
        'Chaque Église particulière peut instituer, modifier ou abolir '
        'des rites et des cérémonies, pourvu que tout se fasse pour '
        'l\'édification.',
      ),
      TextBlock.heading('Article XXIII — Des dirigeants des États-Unis d\'Amérique'),
      TextBlock.p(
        'Le Président, le Congrès, les assemblées générales, les '
        'gouverneurs et les conseils d\'État, en tant que délégués du '
        'peuple, sont les dirigeants des États-Unis d\'Amérique, '
        'conformément à la répartition des pouvoirs établie par la '
        'Constitution des États-Unis et par les constitutions de leurs '
        'États respectifs. Et lesdits États sont une nation souveraine et '
        'indépendante, qui ne doit être soumise à aucune juridiction '
        'étrangère.',
      ),
      TextBlock.note(
        'Pour les Églises hors des États-Unis, cet article se lit à la '
        'lumière du texte « Du devoir des chrétiens envers l\'autorité '
        'civile », plus bas.',
      ),
      TextBlock.heading('Article XXIV — Des biens des chrétiens'),
      TextBlock.p(
        'Les richesses et les biens des chrétiens ne sont pas communs, '
        'quant au droit, au titre et à la possession, comme certains le '
        'prétendent faussement. Néanmoins, chacun doit, de ce qu\'il '
        'possède, donner généreusement l\'aumône aux pauvres, selon ses '
        'moyens.',
      ),
      TextBlock.heading('Article XXV — Du serment du chrétien'),
      TextBlock.p(
        'De même que nous confessons que le serment vain et téméraire est '
        'interdit aux chrétiens par notre Seigneur Jésus-Christ et par '
        'Jacques son apôtre, de même nous jugeons que la religion '
        'chrétienne n\'interdit pas de jurer lorsque le magistrat l\'exige, '
        'dans une cause de foi et de charité, pourvu que cela soit fait '
        'selon l\'enseignement du prophète, dans la justice, le jugement '
        'et la vérité.',
      ),
      TextBlock.heading('De la sanctification'),
      TextBlock.note(
        'Article de la Discipline méthodiste protestante, placé ici par la '
        'Conférence d\'unification de 1939. Il ne fait pas partie des '
        'vingt-cinq articles.',
      ),
      TextBlock.p(
        'La sanctification est ce renouvellement de notre nature déchue '
        'par le Saint-Esprit, reçu par la foi en Jésus-Christ, dont le '
        'sang expiatoire purifie de tout péché ; par elle nous sommes non '
        'seulement délivrés de la culpabilité du péché, mais lavés de sa '
        'souillure, sauvés de son pouvoir, et rendus capables, par la '
        'grâce, d\'aimer Dieu de tout notre cœur et de marcher dans ses '
        'saints commandements sans reproche.',
      ),
      TextBlock.heading('Du devoir des chrétiens envers l\'autorité civile'),
      TextBlock.note(
        'Disposition adoptée par la Conférence d\'unification de 1939 pour '
        'interpréter l\'article XXIII dans les pays autres que les '
        'États-Unis.',
      ),
      TextBlock.p(
        'Il est du devoir de tous les chrétiens, et particulièrement de '
        'tous les ministres chrétiens, d\'observer les lois et les '
        'commandements de l\'autorité qui gouverne le pays dont ils sont '
        'citoyens ou sujets, ou dans lequel ils résident, et d\'y obéir, '
        'et d\'user de tous les moyens louables pour encourager et '
        'recommander l\'obéissance aux autorités établies.',
      ),
    ],
  );

  static const confessionOfFaith = ChurchText(
    id: 'confession_de_foi',
    title: 'La Confession de foi',
    subtitle: 'Les 16 articles de l\'Église évangélique des frères unis',
    icon: ChurchTextIcon.confession,
    source: '$_discipline, ¶ 104',
    blocks: [
      TextBlock.note(
        'Texte de la Discipline de l\'Église évangélique des frères unis '
        '(1963), l\'une des deux Églises qui ont formé l\'Église '
        'Méthodiste Unie en 1968.',
      ),
      TextBlock.heading('Article I — Dieu'),
      TextBlock.p(
        'Nous croyons au Dieu unique, vrai, saint et vivant, Esprit '
        'éternel, créateur, souverain et conservateur de toutes choses '
        'visibles et invisibles. Il est infini en puissance, en sagesse, '
        'en justice, en bonté et en amour, et il règne avec bienveillance '
        'pour le bien et le salut des hommes, à la gloire de son nom. Nous '
        'croyons que le Dieu unique se révèle comme Trinité : Père, Fils '
        'et Saint-Esprit, distincts mais inséparables, éternellement un en '
        'essence et en puissance.',
      ),
      TextBlock.heading('Article II — Jésus-Christ'),
      TextBlock.p(
        'Nous croyons en Jésus-Christ, vraiment Dieu et vraiment homme, en '
        'qui la nature divine et la nature humaine sont parfaitement et '
        'inséparablement unies. Il est le Verbe éternel fait chair, le '
        'Fils unique du Père, né de la Vierge Marie par la puissance du '
        'Saint-Esprit. Serviteur, il a vécu, souffert et est mort sur la '
        'croix. Il a été enseveli, est ressuscité des morts et est monté '
        'au ciel pour être avec le Père, d\'où il reviendra. Il est le '
        'Sauveur et le Médiateur éternel, qui intercède pour nous, et par '
        'lui tous les hommes seront jugés.',
      ),
      TextBlock.heading('Article III — Le Saint-Esprit'),
      TextBlock.p(
        'Nous croyons au Saint-Esprit, qui procède du Père et du Fils et '
        'qui est un avec eux. Il convainc le monde de péché, de justice et '
        'de jugement. Il conduit les hommes, par une réponse fidèle à '
        'l\'Évangile, dans la communion de l\'Église. Il console, soutient '
        'et fortifie les fidèles et les guide dans toute la vérité.',
      ),
      TextBlock.heading('Article IV — La Sainte Bible'),
      TextBlock.p(
        'Nous croyons que la Sainte Bible, Ancien et Nouveau Testament, '
        'révèle la Parole de Dieu dans la mesure où elle est nécessaire à '
        'notre salut. Elle doit être reçue par le Saint-Esprit comme la '
        'vraie règle et le vrai guide de la foi et de la pratique. Tout ce '
        'qui n\'est pas révélé ou établi par les Saintes Écritures ne doit '
        'pas être tenu pour un article de foi, ni enseigné comme essentiel '
        'au salut.',
      ),
      TextBlock.heading('Article V — L\'Église'),
      TextBlock.p(
        'Nous croyons que l\'Église chrétienne est la communauté de tous '
        'les vrais croyants sous la seigneurie du Christ. Nous croyons '
        'qu\'elle est une, sainte, apostolique et catholique. Elle est la '
        'communion rédemptrice dans laquelle la Parole de Dieu est prêchée '
        'par des hommes appelés de Dieu, et les sacrements dûment '
        'administrés selon l\'institution du Christ lui-même. Sous la '
        'discipline du Saint-Esprit, l\'Église existe pour le maintien du '
        'culte, l\'édification des croyants et la rédemption du monde.',
      ),
      TextBlock.heading('Article VI — Les sacrements'),
      TextBlock.p(
        'Nous croyons que les sacrements, institués par le Christ, sont '
        'des symboles et des gages de la profession de foi du chrétien et '
        'de l\'amour de Dieu envers nous. Ils sont des moyens de grâce par '
        'lesquels Dieu agit invisiblement en nous, vivifiant, fortifiant '
        'et confirmant notre foi en lui. Deux sacrements sont institués '
        'par le Christ notre Seigneur, à savoir le baptême et la Cène du '
        'Seigneur.',
      ),
      TextBlock.p(
        'Nous croyons que le baptême signifie l\'entrée dans la famille de '
        'la foi ; il est un symbole de repentance et de purification '
        'intérieure du péché, une représentation de la nouvelle naissance '
        'en Jésus-Christ et une marque de la vie de disciple.',
      ),
      TextBlock.p(
        'Nous croyons que les enfants sont au bénéfice de l\'expiation du '
        'Christ et que, héritiers du Royaume de Dieu, ils peuvent recevoir '
        'le baptême chrétien. Les enfants de parents croyants deviennent, '
        'par le baptême, la responsabilité particulière de l\'Église. Ils '
        'doivent être nourris et conduits à accepter personnellement le '
        'Christ et, par la profession de foi, à confirmer leur baptême.',
      ),
      TextBlock.p(
        'Nous croyons que la Cène du Seigneur est une représentation de '
        'notre rédemption, un mémorial des souffrances et de la mort du '
        'Christ, et un signe de l\'amour et de l\'union que les chrétiens '
        'ont avec le Christ et entre eux. Ceux qui, comme il convient, '
        'dignement et avec foi, mangent le pain rompu et boivent la coupe '
        'bénie, participent au corps et au sang du Christ d\'une manière '
        'spirituelle, jusqu\'à ce qu\'il vienne.',
      ),
      TextBlock.heading('Article VII — Le péché et le libre arbitre'),
      TextBlock.p(
        'Nous croyons que l\'homme est déchu de la justice et que, sans la '
        'grâce de notre Seigneur Jésus-Christ, il est dépourvu de sainteté '
        'et enclin au mal. Si un homme ne naît de nouveau, il ne peut voir '
        'le Royaume de Dieu. Par ses propres forces, sans la grâce divine, '
        'l\'homme ne peut faire de bonnes œuvres agréables et acceptables '
        'à Dieu. Nous croyons cependant que l\'homme, sous l\'influence et '
        'par la force du Saint-Esprit, est responsable, dans la liberté, '
        'd\'exercer sa volonté pour le bien.',
      ),
      TextBlock.heading('Article VIII — La réconciliation par le Christ'),
      TextBlock.p(
        'Nous croyons que Dieu était en Christ, réconciliant le monde avec '
        'lui-même. L\'offrande que le Christ a librement faite sur la '
        'croix est le sacrifice parfait et suffisant pour les péchés du '
        'monde entier, rachetant l\'homme de tout péché, de sorte '
        'qu\'aucune autre satisfaction n\'est requise.',
      ),
      TextBlock.heading('Article IX — Justification et régénération'),
      TextBlock.p(
        'Nous croyons que nous ne sommes jamais tenus pour justes devant '
        'Dieu par nos œuvres ou nos mérites, mais que les pécheurs '
        'repentants sont justifiés, ou tenus pour justes devant Dieu, '
        'uniquement par la foi en notre Seigneur Jésus-Christ.',
      ),
      TextBlock.p(
        'Nous croyons que la régénération est le renouvellement de l\'homme '
        'dans la justice par Jésus-Christ, par la puissance du '
        'Saint-Esprit ; par elle nous devenons participants de la nature '
        'divine et faisons l\'expérience d\'une vie nouvelle. Par cette '
        'nouvelle naissance, le croyant est réconcilié avec Dieu et rendu '
        'capable de le servir par sa volonté et ses affections.',
      ),
      TextBlock.p(
        'Nous croyons que, même après avoir fait l\'expérience de la '
        'régénération, il est possible de s\'éloigner de la grâce et de '
        'tomber dans le péché ; et que nous pouvons, même alors, par la '
        'grâce de Dieu, être renouvelés dans la justice.',
      ),
      TextBlock.heading('Article X — Les bonnes œuvres'),
      TextBlock.p(
        'Nous croyons que les bonnes œuvres sont les fruits nécessaires de '
        'la foi et suivent la régénération, mais qu\'elles n\'ont pas la '
        'vertu d\'effacer nos péchés ni de détourner le jugement divin. '
        'Nous croyons que les bonnes œuvres, agréables et acceptables à '
        'Dieu en Christ, découlent d\'une foi vraie et vivante, car c\'est '
        'par elles que la foi est rendue manifeste.',
      ),
      TextBlock.heading('Article XI — Sanctification et perfection chrétienne'),
      TextBlock.p(
        'Nous croyons que la sanctification est l\'œuvre de la grâce de '
        'Dieu par la Parole et l\'Esprit, par laquelle ceux qui sont nés '
        'de nouveau sont purifiés du péché dans leurs pensées, leurs '
        'paroles et leurs actes, et rendus capables de vivre selon la '
        'volonté de Dieu et de rechercher la sainteté sans laquelle '
        'personne ne verra le Seigneur.',
      ),
      TextBlock.p(
        'L\'entière sanctification est un état d\'amour parfait, de '
        'justice et de vraie sainteté que tout croyant régénéré peut '
        'obtenir en étant délivré du pouvoir du péché, en aimant Dieu de '
        'tout son cœur, de toute son âme, de toute sa pensée et de toute '
        'sa force, et en aimant son prochain comme soi-même. Par la foi en '
        'Jésus-Christ, ce don de la grâce peut être reçu dans cette vie, à '
        'la fois progressivement et instantanément, et tout enfant de Dieu '
        'devrait le rechercher avec ferveur.',
      ),
      TextBlock.p(
        'Nous croyons que cette expérience ne nous délivre pas des '
        'infirmités, de l\'ignorance et des erreurs communes à l\'homme, '
        'ni de la possibilité de pécher encore. Le chrétien doit continuer '
        'à se garder de l\'orgueil spirituel et chercher à remporter la '
        'victoire sur toute tentation de pécher. Il doit répondre '
        'entièrement à la volonté de Dieu, afin que le péché perde son '
        'pouvoir sur lui et que le monde, la chair et le diable soient mis '
        'sous ses pieds. Ainsi il domine ces ennemis, avec vigilance, par '
        'la puissance du Saint-Esprit.',
      ),
      TextBlock.heading('Article XII — Le jugement et l\'état futur'),
      TextBlock.p(
        'Nous croyons que tous les hommes sont sous le juste jugement de '
        'Jésus-Christ, maintenant et au dernier jour. Nous croyons à la '
        'résurrection des morts : les justes pour la vie éternelle et les '
        'méchants pour une condamnation sans fin.',
      ),
      TextBlock.heading('Article XIII — Le culte public'),
      TextBlock.p(
        'Nous croyons que le culte rendu à Dieu est le devoir et le '
        'privilège de l\'homme qui, en présence de Dieu, s\'incline dans '
        'l\'adoration, l\'humilité et la consécration. Nous croyons que le '
        'culte est essentiel à la vie de l\'Église et que le rassemblement '
        'du peuple de Dieu pour ce culte est nécessaire à la communion '
        'fraternelle et à la croissance spirituelle.',
      ),
      TextBlock.p(
        'Nous croyons que l\'ordre du culte public n\'a pas besoin d\'être '
        'partout le même, mais qu\'il peut être modifié par l\'Église '
        'selon les circonstances et les besoins des hommes. Il doit se '
        'dérouler dans une langue et sous une forme que le peuple '
        'comprend, en accord avec les Saintes Écritures, pour '
        'l\'édification de tous, et conformément à l\'ordre et à la '
        'Discipline de l\'Église.',
      ),
      TextBlock.heading('Article XIV — Le jour du Seigneur'),
      TextBlock.p(
        'Nous croyons que le jour du Seigneur est divinement institué '
        'pour le culte privé et public, pour le repos de tout travail qui '
        'n\'est pas nécessaire, et qu\'il doit être consacré au progrès '
        'spirituel, à la communion fraternelle et au service. Il rappelle '
        'la résurrection de notre Seigneur et il est le signe de notre '
        'repos éternel. Il est essentiel à la permanence et à la '
        'croissance de l\'Église chrétienne, et important pour le bien de '
        'la communauté civile.',
      ),
      TextBlock.heading('Article XV — Le chrétien et la propriété'),
      TextBlock.p(
        'Nous croyons que Dieu est le propriétaire de toutes choses et '
        'que la possession de biens par une personne est légitime et '
        'constitue un dépôt sacré confié par Dieu. La propriété privée '
        'doit servir à manifester l\'amour et la générosité du chrétien, '
        'et à soutenir la mission de l\'Église dans le monde. Toutes les '
        'formes de propriété, qu\'elles soient privées, collectives ou '
        'publiques, doivent être tenues comme un dépôt solennel et '
        'utilisées de manière responsable pour le bien de l\'humanité, '
        'sous la souveraineté de Dieu.',
      ),
      TextBlock.heading('Article XVI — Le gouvernement civil'),
      TextBlock.p(
        'Nous croyons que le gouvernement civil tire ses justes pouvoirs '
        'du Dieu souverain. Comme chrétiens, nous reconnaissons les '
        'gouvernements sous la protection desquels nous vivons, et nous '
        'croyons que ces gouvernements doivent se fonder sur la '
        'reconnaissance des droits de l\'homme sous le regard de Dieu, et '
        'en répondre. Nous croyons que la guerre et l\'effusion de sang '
        'sont contraires à l\'Évangile et à l\'esprit du Christ. Nous '
        'croyons qu\'il est du devoir des citoyens chrétiens de donner '
        'force morale et raison d\'être à leurs gouvernements respectifs '
        'par une vie sobre, juste et pieuse.',
      ),
    ],
  );

  static const generalRules = ChurchText(
    id: 'regles_generales',
    title: 'Les Règles générales',
    subtitle: 'Les trois règles de John Wesley',
    icon: ChurchTextIcon.rules,
    source: '$_discipline, ¶ 104',
    blocks: [
      TextBlock.note(
        'Texte de 1808, écrit par John Wesley en 1743 pour les premières '
        'sociétés méthodistes. Son langage est celui de son époque.',
      ),
      TextBlock.heading('Nature, but et règles générales de nos sociétés unies'),
      TextBlock.p(
        'Vers la fin de l\'année 1739, huit ou dix personnes vinrent '
        'trouver M. Wesley à Londres. Elles semblaient profondément '
        'convaincues de péché et soupiraient ardemment après la '
        'rédemption. Elles lui demandèrent, comme le firent deux ou trois '
        'autres le lendemain, de passer quelque temps avec elles en prière '
        'et de leur conseiller comment fuir la colère à venir, qu\'elles '
        'voyaient continuellement suspendue sur leurs têtes. Afin d\'avoir '
        'plus de temps pour cette grande œuvre, il fixa un jour où elles '
        'pourraient toutes se réunir, ce qu\'elles firent dès lors chaque '
        'semaine, le jeudi soir. À ces personnes, et à toutes celles qui '
        'désiraient se joindre à elles (car leur nombre augmentait de jour '
        'en jour), il donnait de temps en temps les conseils qu\'il '
        'jugeait les plus nécessaires, et ils terminaient toujours leur '
        'réunion par une prière adaptée à leurs divers besoins.',
      ),
      TextBlock.p(
        'C\'est ainsi que naquit la Société unie, d\'abord en Europe, puis '
        'en Amérique. Une telle société n\'est rien d\'autre qu\'« une '
        'compagnie de personnes ayant la forme de la piété et en '
        'recherchant la puissance, unies pour prier ensemble, pour '
        'recevoir la parole d\'exhortation et pour veiller les unes sur '
        'les autres dans l\'amour, afin de s\'aider mutuellement à '
        'travailler à leur salut ».',
      ),
      TextBlock.p(
        'Pour que l\'on discerne plus facilement si les membres '
        'travaillent réellement à leur salut, chaque société est divisée '
        'en groupes plus petits, appelés classes, selon le lieu où chacun '
        'habite. Chaque classe compte environ douze personnes, dont l\'une '
        'est appelée le conducteur. Son devoir est :',
      ),
      TextBlock.item(
        'de voir chaque personne de sa classe au moins une fois par '
        'semaine, afin de s\'enquérir de la prospérité de son âme ; de '
        'conseiller, reprendre, consoler ou exhorter, selon les besoins ; '
        'de recevoir ce que chacun veut bien donner pour le soutien des '
        'prédicateurs, de l\'Église et des pauvres ;',
      ),
      TextBlock.item(
        'de rencontrer le ministre et les économes de la société une fois '
        'par semaine, afin d\'informer le ministre de ceux qui sont '
        'malades, ou de ceux qui vivent dans le désordre et ne veulent pas '
        'être repris ; de remettre aux économes ce qu\'il a reçu de sa '
        'classe pendant la semaine écoulée.',
      ),
      TextBlock.p(
        'Une seule condition est requise de ceux qui désirent être admis '
        'dans ces sociétés : « le désir de fuir la colère à venir et '
        'd\'être sauvés de leurs péchés ». Mais partout où ce désir est '
        'réellement fixé dans l\'âme, il se montre par ses fruits.',
      ),
      TextBlock.p(
        'On attend donc de tous ceux qui y demeurent qu\'ils continuent à '
        'manifester leur désir de salut :',
      ),
      TextBlock.heading('Premièrement : ne faire aucun mal'),
      TextBlock.p(
        'En ne faisant aucun mal, en évitant le mal sous toutes ses '
        'formes, particulièrement celui qui se pratique le plus '
        'couramment, comme :',
      ),
      TextBlock.item('prendre le nom de Dieu en vain ;'),
      TextBlock.item(
        'profaner le jour du Seigneur, en y faisant un travail ordinaire, '
        'ou en achetant ou en vendant ;',
      ),
      TextBlock.item(
        'l\'ivrognerie : acheter ou vendre des boissons fortes, ou en '
        'boire, sauf en cas d\'extrême nécessité ;',
      ),
      TextBlock.item('posséder des esclaves ; acheter ou vendre des esclaves ;'),
      TextBlock.item(
        'se battre, se quereller, se disputer ; faire un procès à son '
        'frère ; rendre le mal pour le mal, ou l\'injure pour l\'injure ; '
        'marchander longuement en achetant ou en vendant ;',
      ),
      TextBlock.item('acheter ou vendre des marchandises qui n\'ont pas payé les droits ;'),
      TextBlock.item('prêter ou emprunter à usure, c\'est-à-dire à un intérêt illicite ;'),
      TextBlock.item(
        'tenir des conversations sans charité ou sans profit ; en '
        'particulier, dire du mal des magistrats ou des ministres ;',
      ),
      TextBlock.item('faire aux autres ce que nous ne voudrions pas qu\'ils nous fassent ;'),
      TextBlock.item(
        'faire ce que nous savons ne pas être pour la gloire de Dieu, '
        'comme : porter de l\'or et des vêtements coûteux ;',
      ),
      TextBlock.item(
        'prendre des divertissements dont on ne peut user au nom du '
        'Seigneur Jésus ;',
      ),
      TextBlock.item(
        'chanter des chansons ou lire des livres qui ne portent pas à la '
        'connaissance ou à l\'amour de Dieu ;',
      ),
      TextBlock.item('la mollesse et l\'indulgence inutile envers soi-même ;'),
      TextBlock.item('amasser des trésors sur la terre ;'),
      TextBlock.item(
        'emprunter sans avoir la probabilité de rembourser, ou prendre des '
        'marchandises sans avoir la probabilité de les payer.',
      ),
      TextBlock.heading('Deuxièmement : faire le bien'),
      TextBlock.p(
        'En faisant le bien, en étant miséricordieux de toutes les '
        'manières possibles et, selon les occasions, en faisant toute '
        'sorte de bien, autant que possible, à tous les hommes :',
      ),
      TextBlock.item(
        'à leur corps, selon les moyens que Dieu donne, en donnant de la '
        'nourriture à ceux qui ont faim, en vêtant ceux qui sont nus, en '
        'visitant ou en secourant ceux qui sont malades ou en prison ;',
      ),
      TextBlock.item(
        'à leur âme, en instruisant, en reprenant ou en exhortant tous '
        'ceux avec qui nous sommes en relation ; en foulant aux pieds '
        'cette doctrine exaltée selon laquelle « nous ne devons faire le '
        'bien que si notre cœur y est porté » ;',
      ),
      TextBlock.item(
        'en faisant du bien surtout à ceux qui sont de la famille de la '
        'foi, ou qui soupirent après elle ; en les employant de préférence '
        'à d\'autres, en achetant les uns chez les autres, en s\'entraidant '
        'dans les affaires, d\'autant plus que le monde aime les siens, et '
        'eux seuls ;',
      ),
      TextBlock.item(
        'par toute la diligence et la sobriété possibles, afin que '
        'l\'Évangile ne soit pas blâmé ;',
      ),
      TextBlock.item(
        'en courant avec persévérance dans la carrière qui leur est '
        'ouverte, en renonçant à eux-mêmes et en se chargeant chaque jour '
        'de leur croix ; en acceptant de porter l\'opprobre du Christ, '
        'd\'être comme les balayures et le rebut du monde, et en '
        's\'attendant à ce que les hommes disent faussement d\'eux toute '
        'sorte de mal, à cause du Seigneur.',
      ),
      TextBlock.heading('Troisièmement : observer les ordonnances de Dieu'),
      TextBlock.p('En observant toutes les ordonnances de Dieu, qui sont :'),
      TextBlock.item('le culte public rendu à Dieu ;'),
      TextBlock.item('le ministère de la Parole, lue ou expliquée ;'),
      TextBlock.item('la Cène du Seigneur ;'),
      TextBlock.item('la prière en famille et en privé ;'),
      TextBlock.item('l\'étude des Écritures ;'),
      TextBlock.item('le jeûne ou l\'abstinence.'),
      TextBlock.heading('Conclusion'),
      TextBlock.p(
        'Telles sont les règles générales de nos sociétés ; Dieu nous '
        'enseigne à les observer toutes, dans sa Parole écrite, qui est '
        'la seule règle, et la règle suffisante, de notre foi comme de '
        'notre pratique. Et nous savons que son Esprit les écrit toutes '
        'dans les cœurs vraiment réveillés.',
      ),
      TextBlock.p(
        'S\'il en est parmi nous qui ne les observent pas, qui en '
        'transgressent habituellement l\'une ou l\'autre, qu\'on le fasse '
        'savoir à ceux qui veillent sur cette âme et qui devront en rendre '
        'compte. Nous l\'avertirons de l\'erreur de ses voies. Nous le '
        'supporterons pendant un temps. Mais si, après cela, il ne se '
        'repent pas, il n\'a plus de place parmi nous. Nous aurons délivré '
        'nos propres âmes.',
      ),
    ],
  );

  static const membershipVows = ChurchText(
    id: 'voeux_des_membres',
    title: 'Les vœux des membres',
    subtitle: 'Les engagements de la profession de foi',
    icon: ChurchTextIcon.vows,
    source: '$_discipline, ¶ 217',
    blocks: [
      TextBlock.p(
        'Quand des personnes s\'unissent comme membres professants à une '
        'Église méthodiste unie locale, elles professent leur foi en Dieu, '
        'le Père tout-puissant, créateur du ciel et de la terre, en '
        'Jésus-Christ son Fils unique et au Saint-Esprit. Elles '
        'manifestent ainsi leur désir de vivre leur vie quotidienne en '
        'disciples de Jésus-Christ. Elles s\'engagent envers Dieu et '
        'envers les membres de l\'Église locale à garder les vœux qui font '
        'partie du culte de confirmation et de réception dans l\'Église :',
      ),
      TextBlock.item(
        'renoncer aux forces spirituelles de la méchanceté, rejeter les '
        'puissances mauvaises du monde et se repentir de leur péché ;',
      ),
      TextBlock.item(
        'accepter la liberté et la force que Dieu leur donne pour résister '
        'au mal, à l\'injustice et à l\'oppression ;',
      ),
      TextBlock.item(
        'confesser Jésus-Christ comme Sauveur, mettre toute leur confiance '
        'en sa grâce et promettre de le servir comme leur Seigneur ;',
      ),
      TextBlock.item(
        'demeurer des membres fidèles de la sainte Église du Christ et '
        'servir comme représentants du Christ dans le monde ;',
      ),
      TextBlock.item(
        'être loyales envers le Christ à travers l\'Église Méthodiste Unie '
        'et faire tout ce qui est en leur pouvoir pour fortifier ses '
        'ministères ;',
      ),
      TextBlock.item(
        'participer fidèlement à ses ministères par leurs prières, leur '
        'présence, leurs dons, leur service et leur témoignage ;',
      ),
      TextBlock.item(
        'recevoir et professer la foi chrétienne telle qu\'elle est '
        'contenue dans les Écritures de l\'Ancien et du Nouveau Testament.',
      ),
    ],
  );

  static const mission = ChurchText(
    id: 'mission',
    title: 'La mission de l\'Église',
    subtitle: 'Faire des disciples de Jésus-Christ',
    icon: ChurchTextIcon.mission,
    source: '$_discipline, ¶ 120-122',
    blocks: [
      TextBlock.heading('La mission'),
      TextBlock.p(
        'La mission de l\'Église est de faire des disciples de '
        'Jésus-Christ pour la transformation du monde. Les Églises locales '
        'et les ministères d\'extension de l\'Église sont les lieux les '
        'plus importants où se font les disciples.',
      ),
      TextBlock.heading('La raison d\'être de notre mission'),
      TextBlock.p(
        'La mission de l\'Église est de faire des disciples de '
        'Jésus-Christ pour la transformation du monde, en proclamant la '
        'bonne nouvelle de la grâce de Dieu et en vivant le commandement '
        'de Jésus d\'aimer Dieu et son prochain, recherchant ainsi '
        'l\'accomplissement du règne de Dieu dans le monde. '
        'L\'accomplissement du règne de Dieu dans le monde est la vision '
        'que l\'Écriture nous présente. L\'Église Méthodiste Unie affirme '
        'que Jésus-Christ est le Fils de Dieu, le Sauveur du monde et le '
        'Seigneur de tous. En faisant des disciples, nous respectons les '
        'personnes de toutes les confessions religieuses et nous défendons '
        'la liberté religieuse pour tous.',
      ),
      TextBlock.p(
        'Les paroles de Jésus dans l\'Évangile selon Matthieu donnent à '
        'l\'Église sa mission : « Allez, faites de toutes les nations des '
        'disciples, les baptisant au nom du Père, du Fils et du Saint '
        'Esprit, et enseignez-leur à observer tout ce que je vous ai '
        'prescrit » (Matthieu 28.19-20), et « Tu aimeras le Seigneur, ton Dieu, de '
        'tout ton cœur, de toute ton âme, et de toute ta pensée. […] Tu '
        'aimeras ton prochain comme toi-même » (Matthieu 22.37, 39).',
      ),
      TextBlock.p(
        'Cette mission est notre réponse, portée par la grâce, au règne '
        'de Dieu dans le monde annoncé par Jésus. La grâce de Dieu est à '
        'l\'œuvre partout et en tout temps, accomplissant ce dessein tel '
        'qu\'il est révélé dans la Bible. Il s\'exprime dans l\'alliance '
        'de Dieu avec Abraham et Sara, dans la sortie d\'Égypte du peuple '
        'd\'Israël et dans le ministère des prophètes. Il est pleinement '
        'incarné dans la vie, la mort et la résurrection de Jésus-Christ. '
        'Il se poursuit dans la création continue d\'un peuple nouveau par '
        'le Saint-Esprit.',
      ),
      TextBlock.p(
        'John Wesley, Philip Otterbein, Jacob Albright et nos autres '
        'ancêtres spirituels ont compris cette mission de cette façon. '
        'Chaque fois que le méthodisme uni a eu un sens clair de sa '
        'mission, Dieu s\'est servi de notre Église pour sauver des '
        'personnes, guérir des relations, transformer des structures '
        'sociales et répandre la sainteté selon les Écritures, changeant '
        'ainsi le monde. Pour être vraiment vivants, nous faisons nôtre le '
        'mandat de Jésus d\'aimer Dieu et notre prochain, et de faire de '
        'tous les peuples des disciples.',
      ),
      TextBlock.heading('Comment nous accomplissons notre mission'),
      TextBlock.p('Nous faisons des disciples :'),
      TextBlock.item(
        'en proclamant l\'Évangile, en allant vers les personnes, en les '
        'accueillant et en les rassemblant dans le corps du Christ ;',
      ),
      TextBlock.item(
        'en conduisant les personnes à consacrer leur vie à Dieu par le '
        'baptême d\'eau et d\'Esprit et par la profession de foi en '
        'Jésus-Christ ;',
      ),
      TextBlock.item(
        'en nourrissant les personnes dans la vie chrétienne par le culte, '
        'les sacrements, les disciplines spirituelles et les autres moyens '
        'de grâce, comme l\'entretien fraternel cher à Wesley ;',
      ),
      TextBlock.item(
        'en envoyant les personnes dans le monde pour y vivre avec amour '
        'et justice, en serviteurs du Christ : guérir les malades, nourrir '
        'ceux qui ont faim, prendre soin de l\'étranger, libérer les '
        'opprimés, être une présence de compassion, et travailler à des '
        'structures sociales conformes à l\'Évangile ;',
      ),
      TextBlock.item(
        'en poursuivant la mission d\'aller vers les personnes, de les '
        'accueillir et de les rassembler dans la communauté du corps du '
        'Christ.',
      ),
    ],
  );
}
