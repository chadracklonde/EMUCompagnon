import 'package:flutter/material.dart';

import '../../backup/screens/backup_screen.dart';
import '../../bible/screens/books_screen.dart';
import '../../hymn_lists/screens/hymn_lists_screen.dart';
import '../../journal/screens/journal_screen.dart';
import '../../settings/screens/settings_screen.dart';

/// Un texte en français et en swahili. Les explications de l'aide sont
/// regroupées ici, dans un seul fichier, pour que la relecture du swahili
/// par une personne de langue maternelle se fasse au même endroit.
class L {
  final String fr;
  final String sw;
  const L(this.fr, this.sw);
  String of(String locale) => locale == 'sw' ? sw : fr;
}

/// Une zone touchable sur une capture : son nom, son explication et,
/// quand c'est possible, l'écran réel qu'elle permet d'ouvrir.
class HelpHotspot {
  /// Clé de la zone dans `assets/help/shots.json`.
  final String key;
  final L title;
  final L body;
  final Widget Function()? open;
  const HelpHotspot(this.key, this.title, this.body, {this.open});
}

/// Une capture d'écran (`assets/help/<langue>/<id>.webp`) et ses zones.
class HelpShot {
  final String id;

  /// Description de l'image pour les lecteurs d'écran.
  final L caption;
  final List<HelpHotspot> hotspots;
  const HelpShot(this.id, this.caption, {this.hotspots = const []});
}

class HelpStep {
  final L text;
  final HelpShot? shot;
  const HelpStep(this.text, {this.shot});
}

/// Un sujet de l'aide : une explication en étapes.
class HelpArticle {
  final String id;
  final IconData icon;
  final L title;
  final L subtitle;
  final L intro;
  final List<HelpStep> steps;

  /// Écran de l'application que l'article permet d'ouvrir (facultatif).
  final Widget Function()? open;
  final L? openLabel;

  const HelpArticle({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.intro,
    required this.steps,
    this.open,
    this.openLabel,
  });
}

/// Le contenu de l'aide. Le premier article est celui qu'on met en avant.
class HelpContent {
  static final List<HelpArticle> articles = [
    HelpArticle(
      id: 'start',
      icon: Icons.flag_outlined,
      title: const L('Bien commencer', 'Kuanza vizuri'),
      subtitle: const L('Langue, Bible, taille du texte',
          'Lugha, Biblia, ukubwa wa maandishi'),
      intro: const L(
        'Les premières minutes : choisir sa langue, sa Bible et une taille de texte confortable.',
        'Dakika za kwanza: kuchagua lugha, Biblia na ukubwa wa maandishi unaokufaa.',
      ),
      steps: [
        HelpStep(L(
          'Ouvrez l\'onglet Plus, puis Réglages. Sous « Langue de l\'interface », choisissez Français ou Kiswahili. La Bible et les cantiques suivent la langue.',
          'Fungua kichupo cha Zaidi, kisha Mipangilio. Chini ya « Lugha ya programu », chagua Kifaransa au Kiswahili. Biblia na nyimbo hufuata lugha.',
        ), shot: HelpShot(
          'settings_lang',
          const L('Réglages : langue de l\'interface et taille du texte',
              'Mipangilio: lugha ya programu na ukubwa wa maandishi'),
          hotspots: [
            HelpHotspot(
              'lang',
              const L('Langue de l\'interface', 'Lugha ya programu'),
              const L(
                  'Choisissez Français ou Kiswahili. La Bible et les cantiques suivent la langue.',
                  'Chagua Kifaransa au Kiswahili. Biblia na nyimbo hufuata lugha.'),
              open: () => const SettingsScreen(),
            ),
            HelpHotspot(
              'size',
              const L('Taille du texte', 'Ukubwa wa maandishi'),
              const L(
                  'Faites glisser le curseur pour agrandir ou réduire les versets, les cantiques et les définitions.',
                  'Buruta kitelezi ili kukuza au kupunguza mistari, nyimbo na maelezo.'),
              open: () => const SettingsScreen(),
            ),
          ],
        )),
        HelpStep(L(
          'Dans Lecture, réglez la taille du texte, l\'interligne et la police jusqu\'à lire sans effort.',
          'Katika Usomaji, rekebisha ukubwa wa maandishi, nafasi kati ya mistari na aina ya herufi hadi usome bila shida.',
        )),
        HelpStep(L(
          'Choisissez le thème Clair, Sombre ou Système. « Garder l\'écran allumé » évite que le téléphone s\'éteigne pendant la lecture.',
          'Chagua mandhari Angavu, Giza au Mfumo. « Weka skrini ikiwaka » huzuia simu kuzima wakati wa kusoma.',
        )),
        HelpStep(L(
          'Vous pouvez activer un rappel quotidien et choisir son heure.',
          'Unaweza kuwasha ukumbusho wa kila siku na kuchagua saa yake.',
        )),
      ],
      open: () => const SettingsScreen(),
      openLabel: const L('Ouvrir les Réglages', 'Fungua Mipangilio'),
    ),
    HelpArticle(
      id: 'annotated',
      icon: Icons.menu_book_outlined,
      title: const L('La Bible annotée', 'Biblia yenye maelezo'),
      subtitle: const L('Texte, Étude, Notes, introductions',
          'Maandishi, Funzo, Madokezo, utangulizi'),
      intro: const L(
        'La Bible annotée donne le texte avec les commentaires des auteurs de Neuchâtel. Trois façons de la lire.',
        'Biblia yenye maelezo ina maandishi pamoja na tafsiri za waandishi wa Neuchâtel. Njia tatu za kuisoma.',
      ),
      steps: [
        HelpStep(L(
          'Ouvrez l\'onglet Bible. Sous le titre, choisissez « La Bible annotée » (au lieu de Louis Segond).',
          'Fungua kichupo cha Biblia. Chini ya kichwa, chagua « La Bible annotée » badala ya Louis Segond.',
        ), shot: HelpShot(
          'bible_versions',
          const L('Onglet Bible : choix entre Louis Segond et la Bible annotée',
              'Kichupo cha Biblia: kuchagua kati ya Louis Segond na Biblia yenye maelezo'),
          hotspots: [
            HelpHotspot(
              'version',
              const L('Choix de la Bible', 'Kuchagua Biblia'),
              const L(
                  'Touchez « La Bible annotée » pour lire avec les commentaires, ou Louis Segond pour le texte seul.',
                  'Gusa « La Bible annotée » kusoma pamoja na maelezo, au Louis Segond kwa maandishi peke yake.'),
            ),
          ],
        )),
        HelpStep(L(
          'Ouvrez un chapitre. En haut, trois boutons : Texte (le texte seul), Étude (le début de chaque commentaire sous son verset) et Notes (tous les commentaires du chapitre).',
          'Fungua sura. Juu kuna vitufe vitatu: Maandishi (maandishi peke yake), Funzo (mwanzo wa kila maelezo chini ya mstari wake) na Madokezo (maelezo yote ya sura).',
        ), shot: HelpShot(
          'bible_modes',
          const L('Un chapitre en mode Étude, avec les trois boutons de lecture',
              'Sura katika hali ya Funzo, na vitufe vitatu vya kusoma'),
          hotspots: [
            HelpHotspot(
              'modes',
              const L('Texte · Étude · Notes', 'Maandishi · Funzo · Madokezo'),
              const L(
                  'Texte : le texte seul. Étude : le début du commentaire sous chaque verset. Notes : tous les commentaires du chapitre. Votre choix est gardé.',
                  'Maandishi: maandishi peke yake. Funzo: mwanzo wa maelezo chini ya kila mstari. Madokezo: maelezo yote ya sura. Chaguo lako linahifadhiwa.'),
            ),
          ],
        )),
        HelpStep(L(
          'En mode Étude, touchez « Lire la suite » pour lire la note en entier, « Réduire » pour la refermer.',
          'Katika hali ya Funzo, gusa « Soma zaidi » kusoma dokezo lote, « Punguza » kulifunga.',
        )),
        HelpStep(L(
          'Une note vaut pour les versets qui la précèdent. Les références bibliques dans les notes sont cliquables.',
          'Dokezo moja linahusu mistari iliyo kabla yake. Marejeo ya Biblia ndani ya madokezo yanaweza kuguswa.',
        )),
        HelpStep(L(
          'Dans la liste des chapitres d\'un livre, la ligne « Introduction » présente le livre, son auteur et son plan.',
          'Katika orodha ya sura za kitabu, mstari wa « Utangulizi » unaelezea kitabu, mwandishi wake na mpangilio.',
        ), shot: HelpShot(
          'chapter_intro',
          const L('Liste des chapitres d\'un livre, avec la ligne Introduction',
              'Orodha ya sura za kitabu, na mstari wa Utangulizi'),
          hotspots: [
            HelpHotspot(
              'intro',
              const L('Introduction', 'Utangulizi'),
              const L(
                  'Présente le livre : son auteur, sa date, son plan. Touchez pour la lire ; certains livres ont plusieurs textes.',
                  'Inaelezea kitabu: mwandishi, tarehe na mpangilio. Gusa kuisoma; vitabu vingine vina maandishi kadhaa.'),
            ),
          ],
        )),
      ],
      open: () => const BooksScreen(),
      openLabel: const L('Ouvrir la Bible', 'Fungua Biblia'),
    ),
    HelpArticle(
      id: 'hymns',
      icon: Icons.queue_music,
      title: const L('Cantiques et listes', 'Nyimbo na orodha'),
      subtitle: const L('Écoute, listes personnelles',
          'Kusikiliza, orodha zako'),
      intro: const L(
        'Chanter, écouter un enregistrement et préparer ses cantiques pour un culte.',
        'Kuimba, kusikiliza rekodi na kuandaa nyimbo zako kwa ibada.',
      ),
      steps: [
        HelpStep(L(
          'Dans l\'onglet Cantiques, cherchez par numéro ou par mot. Touchez un cantique pour le lire.',
          'Katika kichupo cha Nyimbo, tafuta kwa nambari au kwa neno. Gusa wimbo kuusoma.',
        )),
        HelpStep(L(
          'Quand « Enregistrement disponible » s\'affiche, vous pouvez écouter le cantique. Dans les Réglages, « Écouter sans connexion » télécharge tous les enregistrements (environ 83 Mo) une seule fois.',
          'Ikionekana « Sauti inapatikana », unaweza kusikiliza wimbo. Katika Mipangilio, kupakua rekodi zote (takriban MB 83) mara moja hukuwezesha kusikiliza bila mtandao.',
        )),
        HelpStep(L(
          'Pour préparer un culte, ouvrez Plus > Listes de cantiques : créez une liste, puis ajoutez-y des cantiques depuis leur page.',
          'Kuandaa ibada, fungua Zaidi > Orodha za nyimbo: tengeneza orodha, kisha weka nyimbo ndani yake kutoka ukurasa wa wimbo.',
        )),
      ],
      open: () => const HymnListsScreen(),
      openLabel: const L('Ouvrir mes listes', 'Fungua orodha zangu'),
    ),
    HelpArticle(
      id: 'journal',
      icon: Icons.edit_note_outlined,
      title: const L('Journal et lecture', 'Shajara na kusoma'),
      subtitle: const L('Prière, plan de lecture, mémorisation',
          'Maombi, mpango wa kusoma, kukariri'),
      intro: const L(
        'Noter ses prières, suivre un plan de lecture et apprendre des versets par cœur.',
        'Kuandika maombi yako, kufuata mpango wa kusoma na kukariri mistari.',
      ),
      steps: [
        HelpStep(L(
          'Plus > Journal de prière : touchez « Nouvelle entrée » pour écrire. Le texte reste sur votre téléphone.',
          'Zaidi > Shajara ya maombi: gusa « Maingizo mapya » ili kuandika. Maandishi yanabaki kwenye simu yako.',
        ), shot: HelpShot(
          'journal',
          const L('Le journal de prière', 'Shajara ya maombi'),
          hotspots: [
            HelpHotspot(
              'new',
              const L('Nouvelle entrée', 'Maingizo mapya'),
              const L('Touchez ce bouton pour écrire. Le texte reste sur votre téléphone.',
                  'Gusa kitufe hiki ili kuandika. Maandishi yanabaki kwenye simu yako.'),
              open: () => const JournalScreen(),
            ),
          ],
        )),
        HelpStep(L(
          'Plus > Plan de lecture : choisissez la durée qui vous convient. L\'application vous indique le passage du jour.',
          'Zaidi > Mpango wa kusoma: chagua muda unaokufaa. Programu inakuonyesha kifungu cha siku.',
        )),
        HelpStep(L(
          'Plus > Mémorisation : ajoutez un verset avec le bouton + en haut, ou depuis les actions d\'un verset dans la Bible, puis révisez-le régulièrement.',
          'Zaidi > Kukariri: ongeza aya kwa kitufe cha + juu, au kupitia vitendo vya aya katika Biblia, kisha uirudie mara kwa mara.',
        )),
      ],
      open: () => const JournalScreen(),
      openLabel: const L('Ouvrir le journal', 'Fungua shajara'),
    ),
    HelpArticle(
      id: 'backup',
      icon: Icons.backup_outlined,
      title: const L('Sauvegarder mes données', 'Kuhifadhi data yangu'),
      subtitle: const L('Changer de téléphone sans rien perdre',
          'Kubadilisha simu bila kupoteza kitu'),
      intro: const L(
        'Vos favoris, notes, journal et progression vivent sur votre téléphone. Une sauvegarde les protège.',
        'Vipendwa, maelezo, shajara na maendeleo yako yako kwenye simu yako. Hifadhi inayalinda.',
      ),
      steps: [
        HelpStep(L(
          'Ouvrez Plus > Sauvegarde de mes données, puis touchez « Exporter mes données ».',
          'Fungua Zaidi > Hifadhi ya data yangu, kisha gusa « Hamisha data yangu ».',
        ), shot: HelpShot(
          'backup',
          const L('L\'écran de sauvegarde', 'Skrini ya kuhifadhi'),
          hotspots: [
            HelpHotspot(
              'export',
              const L('Exporter mes données', 'Hamisha data yangu'),
              const L('Crée un fichier avec vos favoris, notes, journal et progression.',
                  'Hutengeneza faili lenye vipendwa, maelezo, shajara na maendeleo yako.'),
              open: () => const BackupScreen(),
            ),
            HelpHotspot(
              'import',
              const L('Importer une sauvegarde', 'Leta hifadhi'),
              const L('Reprend un fichier créé plus tôt, par exemple sur un nouveau téléphone.',
                  'Hurejesha faili lililotengenezwa awali, kwa mfano kwenye simu mpya.'),
              open: () => const BackupScreen(),
            ),
          ],
        )),
        HelpStep(L(
          'Envoyez le fichier à vous-même (courriel, messagerie ou cloud) pour le garder en lieu sûr.',
          'Jitumie faili hilo (barua pepe, ujumbe au wingu) ili uliweke mahali salama.',
        )),
        HelpStep(L(
          'Sur le nouveau téléphone, touchez « Importer une sauvegarde » et choisissez le fichier.',
          'Kwenye simu mpya, gusa « Leta hifadhi » na uchague faili.',
        )),
      ],
      open: () => const BackupScreen(),
      openLabel: const L('Ouvrir la sauvegarde', 'Fungua hifadhi'),
    ),
  ];

  static HelpArticle? byId(String id) {
    for (final a in articles) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Minuscules et sans accents, pour que « etude » trouve « Étude ».
  static String fold(String s) {
    const from = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿœæ';
    const to = 'aaaaaceeeeiiiinooooouuuuyyoa';
    final b = StringBuffer();
    for (final c in s.toLowerCase().split('')) {
      final i = from.indexOf(c);
      b.write(i < 0 ? c : to[i]);
    }
    return b.toString();
  }

  /// Les articles qui contiennent tous les mots de [query].
  static List<HelpArticle> search(String query, String locale) {
    final words =
        fold(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return articles;
    return [
      for (final a in articles)
        if (_matches(a, words, locale)) a,
    ];
  }

  static bool _matches(HelpArticle a, List<String> words, String locale) {
    final text = fold([
      a.title.of(locale),
      a.subtitle.of(locale),
      a.intro.of(locale),
      for (final s in a.steps) s.text.of(locale),
    ].join(' '));
    return words.every(text.contains);
  }
}
