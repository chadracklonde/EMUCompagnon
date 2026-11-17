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

  const BibleVersion({
    required this.code,
    required this.name,
    required this.language,
    required this.available,
    this.note,
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
    note: 'CC BY-SA 4.0, © Biblica, Inc., 2018 ; édition Aionian (AionianBible.org)',
  );

  /// All versions the app knows about, available or not. The UI filters
  /// or grays out unavailable ones as appropriate.
  static const all = [lsg1910, scv, suv];

  static const availableVersions = [lsg1910, scv];

  static BibleVersion byCode(String code) =>
      all.firstWhere((v) => v.code == code, orElse: () => lsg1910);
}
