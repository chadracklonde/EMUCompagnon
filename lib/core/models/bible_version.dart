/// Metadata for one Bible translation available (or planned) in the app.
/// [available] is false for versions not yet loaded into the database —
/// they still appear in the version picker as "à venir" so the UI is
/// ready the moment the text is licensed and imported, with zero code
/// changes needed beyond flipping this flag and importing the data.
class BibleVersion {
  final String code; // matches bible_verses.version in the DB
  final String name;
  final String language;
  final bool available;
  final String? note;

  /// True quand la version a des notes de commentaire (la Bible annotée) :
  /// l'écran de lecture propose alors les modes Texte, Étude et Notes.
  final bool hasNotes;

  /// Site de l'auteur de la numérisation à citer, et la ligne de crédit
  /// affichée sous le texte (quand la version en demande une).
  final String? creditUrl;
  final String? creditLine;

  const BibleVersion({
    required this.code,
    required this.name,
    required this.language,
    required this.available,
    this.note,
    this.hasNotes = false,
    this.creditUrl,
    this.creditLine,
  });
}

class BibleVersions {
  static const lsg1910 = BibleVersion(
    code: 'LSG1910',
    name: 'Louis Segond 1910',
    language: 'Français',
    available: true,
  );

  static const suv = BibleVersion(
    code: 'SUV',
    name: 'Swahili Union Version',
    language: 'Kiswahili',
    available: false,
    note: 'En attente d\'autorisation des Bible Societies of Tanzania/Kenya',
  );

  static const scv = BibleVersion(
    code: 'SCV',
    name: 'Biblia Takatifu Wazi (Swahili Contemporary Version)',
    language: 'Kiswahili',
    available: true,
    note:
        'CC BY-SA 4.0, © Biblica, Inc., 2018 ; édition Aionian (AionianBible.org)',
  );

  /// La Bible annotée (traduction et notes), numérisée par Claude Royère
  /// (ThéoTeX), qui a autorisé son usage et demandé un lien vers theotex.org.
  static const annotee = BibleVersion(
    code: 'BA',
    name: 'La Bible annotée',
    language: 'Français',
    available: true,
    note: 'Avec notes · numérisation ThéoTeX, theotex.org',
    hasNotes: true,
    creditUrl: 'https://theotex.org',
    creditLine: 'La Bible annotée · numérisation ThéoTeX (Claude Royère), '
        'notes du Nouveau Testament numérisées par Yves Petrakian',
  );

  /// All versions the app knows about, available or not. The UI filters
  /// or grays out unavailable ones as appropriate.
  static const all = [lsg1910, annotee, scv, suv];

  static const availableVersions = [lsg1910, annotee, scv];

  static BibleVersion byCode(String code) =>
      all.firstWhere((v) => v.code == code, orElse: () => lsg1910);
}
