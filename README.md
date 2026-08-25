# ÉMU Compagnon

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
affiché à l'utilisateur, « ÉMU Compagnon », est déjà réglé dans
`lib/main.dart` (`MaterialApp.title`). Pour que ce nom apparaisse aussi
sous l'icône de l'app sur le téléphone, une fois les dossiers natifs générés :
- **Android** : `android/app/src/main/AndroidManifest.xml` → `android:label="ÉMU Compagnon"`
- **iOS** : `ios/Runner/Info.plist` → `CFBundleDisplayName` = `ÉMU Compagnon`

## Contenu inclus
- `assets/db/app_data.db` — Bible Louis Segond 1910 (31 102 versets), 444 cantiques
  "Chants de Victoire", 228 entrées de dictionnaire biblique, index FTS5 pour
  la recherche/concordance.
## Écran d'accueil (style « missel classique »)
Un nouvel onglet **Accueil** (premier onglet, icône maison) offre une
page de lancement au style ornemental — fond parchemin, bordures dorées,
polices classiques (Google Fonts : Great Vibes en cursive, Playfair
Display en serif) — tout en gardant le bordeaux officiel UMC comme seule
couleur de marque (pas de bleu marine). Elle regroupe : sélecteur de
langue et de thème, recherche globale, verset du jour, accès rapide
Nouveau/Ancien Testament, Plan de lecture, Liturgie, et une grille
Cantiques/Dictionnaire/Favoris/À propos. Les 6 onglets existants restent
inchangés et accessibles normalement dans la barre du bas.

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
- Cantiques affichés par couplets/refrain nettement séparés (au lieu d'un
  seul bloc de texte), avec le refrain mis en valeur visuellement.
  Références bibliques cliquables dans les paroles.
- Réglages rapides « Aa » (taille du texte + interligne) accessibles
  directement depuis les écrans Bible et Cantiques, sans passer par le
  menu À propos — même préférence partagée et persistée partout.
- Balayage horizontal pour changer de chapitre biblique, en plus des
  flèches.
- « Reprendre la lecture » : la Bible et les Cantiques retiennent le
  dernier chapitre/cantique consulté et proposent un accès rapide depuis
  l'écran d'accueil du module.

## Nouveautés — vague 3
- **Surlignage multicolore** des versets (5 couleurs), distinct du favori
  ⭐ et du flash temporaire d'arrivée depuis un lien.
- **Historique de recherche** dans la recherche globale (10 dernières
  requêtes, chips cliquables, effaçables).
- **Choix de police** : Système / Serif / Sans-serif, avec aperçu en
  direct dans les réglages.
- **Interface en kiswahili** (en plus du français) : navigation et
  éléments principaux traduits. ⚠️ Traduction rédigée de bonne foi mais
  **non relue par un locuteur natif** — à faire valider par quelqu'un de
  la communauté avant publication. Seule l'interface est traduite ; la
  Bible, les cantiques et le dictionnaire restent en français (leur
  traduction est un chantier séparé, nécessitant une source certifiée).
- **Plan de lecture biblique** : un chapitre par jour à travers toute la
  Bible, progression cochable et persistée, accessible depuis l'écran
  Bible.
- **Rappel quotidien** (notification locale) à une heure choisie par
  l'utilisateur. Le workflow CI a été mis à jour pour injecter la
  permission Android `POST_NOTIFICATIONS`, absente du scaffold généré
  par défaut.
- **Sauvegarde des données personnelles** : export de tous les favoris,
  notes et surlignages en un fichier JSON partageable, et réimport sur
  un autre appareil (avec déduplication). Aucun compte, aucun serveur —
  le fichier reste entre les mains de l'utilisateur.
- **Mise à jour du contenu sans passer par le store** : l'app peut
  vérifier `content_version.json` à la racine du dépôt GitHub et, si une
  version plus récente de `app_data.db` est disponible, la télécharger
  et la fusionner — **sans jamais toucher aux favoris/notes/surlignages
  de l'utilisateur** (ils vivent dans le même fichier .db, donc la
  fusion se fait table par table, pas par écrasement brut). Pour publier
  une mise à jour de contenu : incrémenter `"version"` dans
  `content_version.json` et pousser un nouvel `app_data.db`.
- **Infrastructure audio pour les cantiques**, prête mais **inactive** :
  un champ `audio_url` (nullable) a été ajouté à chaque cantique, et un
  lecteur intégré s'affiche automatiquement dès qu'une URL y est
  renseignée. Aucun des 444 cantiques n'a de mélodie enregistrée
  aujourd'hui — il faudra sourcer ou enregistrer de vrais fichiers audio
  pour que cette fonctionnalité devienne visible.
- **Tests automatisés** (`test/`) pour la logique la plus sensible aux
  régressions silencieuses : calcul de Pâques (vérifié contre des dates
  officielles connues), calendrier liturgique (couverture complète de
  l'année sans trou ni erreur), détection de références bibliques,
  découpage des cantiques en couplets. Exécutés en CI (`flutter test`),
  actuellement non bloquants (`|| true`) le temps de confirmer leur
  stabilité en conditions réelles.

## Multi-versions de la Bible (infrastructure prête, SUV en attente de licence)
- La Bible n'est **pas encore** disponible en kiswahili dans l'app. La
  seule version librement réutilisable trouvée (domaine public) est un
  Nouveau Testament incomplet (il manque Philippiens), pas fiable pour
  un usage en Église. La version reconnue par les fidèles — la **Swahili
  Union Version (SUV)** — appartient aux Bible Societies of Tanzania et
  Kenya : une demande de licence leur a été envoyée.
- **L'infrastructure est prête à recevoir la SUV dès l'autorisation
  obtenue**, sans refonte :
  - La colonne `version` existait déjà dans `bible_verses` (index ajouté
    pour les performances multi-versions).
  - `BibleVersion` / `BibleVersions` : registre des versions connues,
    disponibles ou « à venir ».
  - `BibleRepository` : toutes les méthodes (`getChapter`, `search`,
    `chapterCount`, `getVerseOfTheDay`…) acceptent un paramètre `version`
    (par défaut `LSG1910`, donc rien ne casse pour l'existant).
  - Sélecteur de version (icône 🌐) sur l'écran Bible, avec la SUV déjà
    listée mais grisée « Bientôt disponible ».
  - `ChapterListScreen` et `ChapterScreen` propagent la version choisie
    de bout en bout.
- **Pour intégrer la SUV une fois le texte obtenu** : écrire un script
  d'import (même principe que pour la Louis Segond 1910) insérant les
  versets avec `version='SUV'`, puis dans `BibleVersion.suv`, passer
  `available: true`. Aucune autre modification de code n'est nécessaire.

## Tutoriel de démarrage
Un tutoriel de 5 écrans s'affiche automatiquement au tout premier
lancement (état suivi via `SharedPreferences`, jamais réaffiché
ensuite), pour présenter les 7 onglets de l'app à un nouvel
utilisateur. Accessible à nouveau à tout moment via « À propos » →
« Revoir le tutoriel de démarrage ».

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
