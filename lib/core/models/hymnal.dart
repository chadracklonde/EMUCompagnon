/// Les recueils de cantiques de l'application. Le recueil affiché suit la
/// langue : « Chants de Victoire » en français, « Nyimbo za Wokovu » en
/// swahili. Les deux vivent dans la table `hymns` (colonne `hymnal`).
class Hymnals {
  static const cv = 'CV';
  static const nzw = 'NZW';

  static String forLocale(String locale) => locale == 'sw' ? nzw : cv;

  static String name(String hymnal) => hymnal == nzw ? 'Nyimbo za Wokovu' : 'Chants de Victoire';
}
