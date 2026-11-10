/// Lightweight, hand-written translation table — not Flutter's generated
/// l10n system (which needs the Flutter SDK to run `flutter gen-l10n`,
/// unavailable in the environment this was built in). Covers navigation
/// labels and the most visible screen titles/buttons.
///
/// IMPORTANT: the Swahili strings below were written in good faith but
/// have NOT been reviewed by a native Kiswahili/Kingwana speaker. Please
/// have someone from the Maniema community proofread them before
/// shipping — a few words may need local dialect adjustment.
///
/// This does NOT translate the Bible, hymn, or dictionary CONTENT itself
/// (31,000+ verses, 444 hymns) — only the app's own interface chrome.
/// Translating the Bible content requires a proper certified Swahili
/// translation source, not something to generate here.
class AppStrings {
  static const Map<String, Map<String, String>> _table = {
    'fr': {
      'nav_bible': 'Bible',
      'nav_hymns': 'Cantiques',
      'nav_liturgy': 'Liturgie',
      'nav_dictionary': 'Dictionnaire',
      'nav_favorites': 'Favoris',
      'nav_about': 'À propos',
      'search': 'Rechercher',
      'search_everywhere': 'Rechercher dans toute l\'app…',
      'close': 'Fermer',
      'add': 'Ajouter',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'settings_display': 'Affichage',
      'verse_of_the_day': 'Verset du jour',
      'resume_reading': 'Reprendre la lecture',
      'no_results': 'Aucun résultat',
      'notes': 'Notes',
      'highlight': 'Surligner',
      'share': 'Partager',
      'copy': 'Copier',
      'nav_home': 'Accueil',
      'nav_more': 'Plus',
      'greeting_day': 'Bonjour',
      'greeting_evening': 'Bonsoir',
      'streak_days': '{n} jours de suite',
      'language': 'Langue',
      'theme_toggle': 'Changer de thème',
      'settings': 'Réglages',
      'verse_unavailable': 'Le verset du jour n\'a pas pu être chargé.',
      'favorite_add': 'Ajouter aux favoris',
      'favorite_remove': 'Retirer des favoris',
      'section_read_sing': 'Lire et chanter',
      'section_today': 'Aujourd\'hui',
      'section_spiritual_life': 'Vie spirituelle',
      'section_library': 'Bibliothèque',
      'section_app': 'Application',
      'old_testament': 'Ancien Testament',
      'new_testament': 'Nouveau Testament',
      'books_count': '{n} livres',
      'hymnal_subtitle': 'Recueil de cantiques',
      'liturgy_subtitle': 'Calendrier et cultes',
      'reading_plan': 'Plan de lecture',
      'reading_plan_next': 'À lire : {ref}',
      'reading_plan_done': 'Plan terminé',
      'reading_plan_progress': '{done} sur {total} chapitres lus',
      'daily_quiz': 'Quiz du jour',
      'daily_quiz_questions': '{n} questions',
      'daily_quiz_done': 'Terminé · {score}/{total}',
      'memorization': 'Mémorisation',
      'prayer_journal': 'Journal de prière',
      'evening_examen': 'Examen du soir',
      'weekly_challenge': 'Défi de la semaine',
      'dictionary_full': 'Dictionnaire biblique',
    },
    'sw': {
      'nav_bible': 'Biblia',
      'nav_hymns': 'Nyimbo',
      'nav_liturgy': 'Liturujia',
      'nav_dictionary': 'Kamusi',
      'nav_favorites': 'Vipendwa',
      'nav_about': 'Kuhusu',
      'search': 'Tafuta',
      'search_everywhere': 'Tafuta katika programu yote…',
      'close': 'Funga',
      'add': 'Ongeza',
      'cancel': 'Ghairi',
      'save': 'Hifadhi',
      'delete': 'Futa',
      'settings_display': 'Muonekano',
      'verse_of_the_day': 'Aya ya Siku',
      'resume_reading': 'Endelea Kusoma',
      'no_results': 'Hakuna matokeo',
      'notes': 'Vidokezo',
      'highlight': 'Weka Rangi',
      'share': 'Shiriki',
      'copy': 'Nakili',
      'nav_home': 'Nyumbani',
      'nav_more': 'Zaidi',
      'greeting_day': 'Hujambo',
      'greeting_evening': 'Habari za jioni',
      'streak_days': 'Siku {n} mfululizo',
      'language': 'Lugha',
      'theme_toggle': 'Badilisha mandhari',
      'settings': 'Mipangilio',
      'verse_unavailable': 'Aya ya siku haikuweza kupakiwa.',
      'favorite_add': 'Ongeza kwenye vipendwa',
      'favorite_remove': 'Ondoa kwenye vipendwa',
      'section_read_sing': 'Soma na Imba',
      'section_today': 'Leo',
      'section_spiritual_life': 'Maisha ya kiroho',
      'section_library': 'Maktaba',
      'section_app': 'Programu',
      'old_testament': 'Agano la Kale',
      'new_testament': 'Agano Jipya',
      'books_count': 'Vitabu {n}',
      'hymnal_subtitle': 'Kitabu cha nyimbo',
      'liturgy_subtitle': 'Kalenda na ibada',
      'reading_plan': 'Mpango wa kusoma',
      'reading_plan_next': 'Ya kusoma: {ref}',
      'reading_plan_done': 'Mpango umekamilika',
      'reading_plan_progress': 'Sura {done} kati ya {total} zimesomwa',
      'daily_quiz': 'Jaribio la siku',
      'daily_quiz_questions': 'Maswali {n}',
      'daily_quiz_done': 'Imekamilika · {score}/{total}',
      'memorization': 'Kukariri',
      'prayer_journal': 'Shajara ya maombi',
      'evening_examen': 'Tafakari ya jioni',
      'weekly_challenge': 'Changamoto ya wiki',
      'dictionary_full': 'Kamusi ya Biblia',
    },
  };

  static String t(String key, String locale) {
    return _table[locale]?[key] ?? _table['fr']?[key] ?? key;
  }

  /// Like [t], then replaces each `{name}` placeholder with its value.
  static String tf(String key, String locale, Map<String, Object> values) {
    var text = t(key, locale);
    values.forEach((name, value) {
      text = text.replaceAll('{$name}', '$value');
    });
    return text;
  }

  static const _weekdays = {
    'fr': ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
    'sw': ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'],
  };

  static const _months = {
    'fr': [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ],
    'sw': [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
    ],
  };

  /// "Mardi 10 novembre" / "Jumanne 10 Novemba".
  static String longDate(DateTime date, String locale) {
    final lang = _weekdays.containsKey(locale) ? locale : 'fr';
    final weekday = _weekdays[lang]![date.weekday - 1];
    final month = _months[lang]![date.month - 1];
    final day = lang == 'fr' && date.day == 1 ? '1er' : '${date.day}';
    return '$weekday $day $month';
  }
}
