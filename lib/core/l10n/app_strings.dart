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
    },
  };

  static String t(String key, String locale) {
    return _table[locale]?[key] ?? _table['fr']?[key] ?? key;
  }
}
