# EMU Compagnon

Application mobile Flutter pour l'Église Méthodiste Unie : Bible, Cantiques
« Chants de Victoire », Dictionnaire biblique, et (à venir) Liturgie EMU.

## Démarrage
```
flutter create . --project-name emu_compagnon   # si les dossiers android/ios manquent encore
flutter pub get
flutter run
```

## Nom d'affichage sur les appareils
Le nom technique du package est `emu_compagnon` (`pubspec.yaml`). Le nom
affiché à l'utilisateur, « EMU Compagnon », est déjà réglé dans
`lib/main.dart` (`MaterialApp.title`). Pour que ce nom apparaisse aussi
sous l'icône de l'app sur le téléphone, une fois les dossiers natifs générés :
- **Android** : `android/app/src/main/AndroidManifest.xml` → `android:label="EMU Compagnon"`
- **iOS** : `ios/Runner/Info.plist` → `CFBundleDisplayName` = `EMU Compagnon`

## Contenu inclus
- `assets/db/app_data.db` — Bible Louis Segond 1910 (31 102 versets), 444 cantiques
  "Chants de Victoire", 228 entrées de dictionnaire biblique, index FTS5 pour
  la recherche/concordance.
- Modules actifs : Bible (navigation livre/chapitre + concordance + étoile
  favoris par verset + verset du jour), Cantiques (liste + recherche +
  détail + étoile favoris), Liturgie (calendrier liturgique : saison du
  jour calculée automatiquement, dates mobiles de Pâques/Carême/Pentecôte
  recalculées chaque année, frise des 6 saisons + 4 jours saints),
  Dictionnaire biblique (liste alphabétique + recherche), Favoris (onglet
  dédié, versets et cantiques enregistrés, retrait en un tap), À propos
  (crédit développeur, contact, liens UMC, accès aux réglages d'affichage).
- Contenu du calendrier liturgique rédigé indépendamment pour cette app
  (pas de reproduction d'un texte protégé) ; dates calculées, pas codées
  en dur, donc toujours justes d'une année sur l'autre.
- Accessibilité et confort de lecture : mode sombre/clair/système, taille
  du texte et interligne réglables (persistés localement), références
  bibliques cliquables dans le dictionnaire et la liturgie (ex. « Jean
  3.16 » ouvre directement le verset avec surlignage et défilement
  automatique), copie d'un verset par appui long, versets nettement
  séparés visuellement (fond, marge, encadré au survol/lien).
- Recherche globale : un seul champ de recherche interroge simultanément
  la Bible, les cantiques et le dictionnaire (FTS5 en parallèle sur les
  trois sources), résultats par onglets.
- Notes personnelles : en plus des favoris, chaque verset peut recevoir
  une ou plusieurs notes libres (table `notes`), consultables/éditables
  depuis le menu « ⋮ » d'un verset ou depuis l'onglet Notes de Favoris.
- Partage d'un verset comme image : génère une carte visuelle brandée
  (dégradé bordeaux UMC, texte du verset, référence) et l'envoie au
  partage natif du système (`share_plus`).
- Module Liturgie étoffé : en plus du calendrier liturgique, un « Ordre
  du culte » (structure générale d'un service dominical méthodiste) et
  une section « Sacrements et rites » (Baptême, Sainte-Cène, Confirmation,
  Mariage, Funérailles). Contenu rédigé indépendamment (structure et sens
  général, pas les textes liturgiques officiels protégés — prières, vœux,
  bénédictions exacts — qui restent à prendre dans le Livre de Culte EMU
  officiel).

## Générer un APK automatiquement (GitHub Actions)
Le fichier `.github/workflows/build.yml` construit l'app automatiquement :
- **À chaque push sur `main`** : compile l'APK et l'AAB, disponibles comme
  "artefact" téléchargeable dans l'onglet **Actions** de GitHub (conservé 30 jours).
- **En poussant un tag de version** (ex. `git tag v1.0.0 && git push --tags`) :
  crée en plus une **Release GitHub** avec l'APK directement attaché,
  prêt à partager par un lien.

Aucune configuration supplémentaire n'est nécessaire pour cette première
mise en place ; l'APK produit est signé avec la clé de debug par défaut de
Flutter (suffisant pour des tests entre proches, pas pour le Play Store —
voir la section signature plus bas si besoin).

## Icône de l'application
Le logo (croix et flamme, sur fond bordeaux #731932) est déjà dans
`assets/icons/` et configuré dans `pubspec.yaml` via `flutter_launcher_icons`.
Pour générer les icônes natives iOS/Android à partir de ce fichier unique :
```
flutter pub get
dart run flutter_launcher_icons
```
Cela crée automatiquement toutes les tailles nécessaires (y compris l'icône
adaptative Android, qui utilise `app_icon_foreground.png` — le motif seul,
fond transparent — posé sur le fond bordeaux `#731932`).

## Non testé dans cet environnement
Ce code a été écrit directement (pas de SDK Flutter disponible dans le
bac à sable où il a été généré). Avant de committer : `flutter pub get`
puis `flutter analyze` pour attraper d'éventuelles fautes de frappe, et
tester sur un simulateur ou appareil réel.

## Prochaines étapes suggérées
1. `flutter pub get` + `flutter run` pour valider
2. Régler le nom d'affichage natif (voir ci-dessus) + icône d'app
3. Ajouter les favoris/signets (table `bookmarks` déjà prête dans la DB)
4. Étoffer encore le dictionnaire si besoin
5. Ajouter le module Liturgie une fois le contenu prêt
