import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/settings/app_settings.dart';
import '../features/bible/repository/bible_repository.dart';

/// Noms swahilis des 66 livres, dans le même ordre que
/// [BibleRepository.books] (noms de la table des matières de la Biblia
/// Takatifu Wazi). Dans la base, les livres restent identifiés par leur
/// nom français : ces noms ne servent qu'à l'affichage.
class BibleBookNames {
  static const List<String> sw = [
    'Mwanzo', 'Kutoka', 'Mambo ya Walawi', 'Hesabu', 'Torati',
    'Yoshua', 'Waamuzi', 'Ruth', '1 Samweli', '2 Samweli', '1 Wafalme', '2 Wafalme',
    '1 Nyakati', '2 Nyakati', 'Ezra', 'Nehemia', 'Esta',
    'Ayubu', 'Zaburi', 'Mithali', 'Mhubiri', 'Wimbo wa Sulemani',
    'Isaya', 'Yeremia', 'Maombolezo', 'Ezekieli', 'Danieli',
    'Hosea', 'Joeli', 'Amosi', 'Obadia', 'Yona', 'Mika', 'Nahumu',
    'Habakuki', 'Sefania', 'Hagai', 'Zekaria', 'Malaki',
    'Mathayo', 'Marko', 'Luka', 'Yohana', 'Matendo',
    'Warumi', '1 Wakorintho', '2 Wakorintho', 'Wagalatia', 'Waefeso',
    'Wafilipi', 'Wakolosai', '1 Wathesalonike', '2 Wathesalonike',
    '1 Timotheo', '2 Timotheo', 'Tito', 'Filemoni', 'Wahebrania',
    'Yakobo', '1 Petro', '2 Petro', '1 Yohana', '2 Yohana', '3 Yohana',
    'Yuda', 'Ufunuo',
  ];

  /// Vrai quand les noms de livres doivent être affichés en swahili :
  /// application en swahili, ou Bible swahilie choisie.
  static bool useSwahili({required String locale, String? version}) =>
      locale == 'sw' || version == 'SCV';

  /// Nom à afficher pour [book] (nom français canonique).
  static String display(String book, {required String locale, String? version}) {
    if (!useSwahili(locale: locale, version: version)) return book;
    final i = BibleRepository.books.indexOf(book);
    return i < 0 ? book : sw[i];
  }

  /// Remplace le nom de livre au début d'une référence « Livre 3.16 ».
  static String displayReference(String reference,
      {required String locale, String? version}) {
    if (!useSwahili(locale: locale, version: version)) return reference;
    for (final book in BibleRepository.books) {
      if (reference.startsWith('$book ')) {
        return display(book, locale: locale, version: version) +
            reference.substring(book.length);
      }
    }
    return reference;
  }
}

extension BibleBookNamesContext on BuildContext {
  /// Nom de livre à afficher, selon la langue de l'application et la
  /// version de la Bible ([version] vaut par défaut la version choisie).
  String bookName(String book, {String? version}) {
    final s = watch<AppSettings>();
    return BibleBookNames.display(book,
        locale: s.locale, version: version ?? s.bibleVersion);
  }

  String bookReference(String reference, {String? version}) {
    final s = watch<AppSettings>();
    return BibleBookNames.displayReference(reference,
        locale: s.locale, version: version ?? s.bibleVersion);
  }
}
