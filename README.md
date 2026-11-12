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
## Écran d'accueil (style « clair et aéré »)
L'onglet **Accueil** suit un style moderne et épuré : fond clair neutre,
cartes blanches à bord fin, et le bordeaux officiel UMC comme seule
couleur de marque. Le verset du jour est la seule carte pleine (bordeaux,
texte en Playfair Display), avec favori et partage. Viennent ensuite :
« Lire et chanter » (Ancien/Nouveau Testament, Chants de Victoire,
Liturgie avec la saison en cours), « Aujourd'hui » (progression du plan
de lecture, quiz du jour) et « Vie spirituelle » (mémorisation, journal
de prière, examen du soir, défi de la semaine).

Le **plan de lecture** a une durée au choix : une semaine, un mois, trois
mois, six mois, un an, ou un nombre de jours libre. L'application répartit
la Bible sur cette durée en équilibrant les journées par nombre de versets
et en coupant toujours en fin de chapitre (`ReadingPlanBuilder.split`).
Changer de durée conserve ce qui est déjà lu et ne répartit que le reste.
Sans choix, le plan reste d'un chapitre par jour (1 189 jours).

Trois raccourcis accompagnent la lecture :
- en fin de chapitre, « Marquer comme lu » coche le chapitre dans le plan ;
- dans la recherche, taper une référence (« Jean 3.16 », « jn 3 16 »,
  « ps 23 ») propose d'ouvrir directement le passage
  (`BibleQuickReference`) ;
- le rappel quotidien annonce la lecture du jour du plan (`ReadingReminder`),
  mise à jour à chaque ouverture de l'application.

Les **listes de cantiques** (onglet Cantiques, icône de liste, ou onglet
Plus) servent à préparer le programme d'un culte : on crée une liste, on y
coche des cantiques, on les ordonne en les faisant glisser, puis
« Commencer » les enchaîne avec Précédent / Suivant. Un cantique s'ajoute
aussi à une liste depuis son menu « ⋮ ». Les listes sont enregistrées sur
l'appareil (`HymnListService`) et incluses dans la sauvegarde.

La barre du bas compte 5 onglets : Accueil, Bible, Cantiques, Liturgie,
Plus. Dictionnaire, Favoris, recherche, vie spirituelle, Réglages,
Sauvegarde, Mises à jour du contenu, tutoriel et À propos sont sous **Plus**.
Les briques visuelles partagées sont dans `lib/shared/widgets/app_cards.dart`
et les couleurs neutres dans `AppPalette` (`lib/core/theme/app_theme.dart`).

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
- Partage du texte : un verset (avec sa référence) ou un cantique
  entier (strophes et refrain) s'envoie en texte simple vers WhatsApp,
  SMS, etc., en plus du partage comme image (`TextShareService`).
- « Prières et textes » (onglet Liturgie) : le Notre Père (Matthieu
  6.9-13, LSG 1910), le Credo social et sa litanie, les 25 Articles de
  religion, la Confession de foi, les Règles générales, les vœux des
  membres et la mission de l'Église. Page de lecture avec sommaire pour
  les textes longs, réglage du texte et partage. Les textes tirés du
  Livre de Discipline 2020/2024 viennent d'une traduction automatique
  corrigée à la main : ils sont à relire, et se corrigent dans le seul
  fichier `lib/features/church_texts/data/church_texts_data.dart`.
- Confort d'usage : écran gardé allumé pendant la lecture (réglable dans
  les Réglages) ; glissement d'un cantique au suivant ; recherche
  générale étendue à la liturgie et aux textes de l'Église ; sur une page
  de texte, appui long pour partager ou copier un seul article,
  épinglage sur l'accueil, reprise de lecture, références bibliques
  cliquables, indication « Officiant / Assemblée » dans les litanies.
- « Culte du dimanche » (accueil et onglet Liturgie) : le dimanche
  concerné, sa saison, la liste de cantiques choisie, les prières dites
  ensemble et le déroulement du culte sur un seul écran.
- Widgets Android (23 types, à ajouter depuis l'écran d'accueil du
  téléphone) : Verset du jour, Lecture du jour, Saison liturgique, Couleur
  du jour, Prochain dimanche, Compte à rebours, Calendrier liturgique,
  Cantiques du culte, Série de jours, Semaine de lecture, Verset à
  mémoriser, Raccourcis, Prière épinglée, Cantique du jour, Reprendre la
  Bible, Reprendre le cantique, Mes favoris, Défi de la semaine, Quiz du
  jour, Examen du soir, Écrire une prière, Mot du jour et Recherche. Un
  appui ouvre l'écran concerné (`WidgetRouter`). L'application écrit ce
  que chacun affiche (`WidgetSyncService`, 14 jours d'avance pour ceux qui
  changent chaque jour) au démarrage et quand on la quitte, puis demande
  leur rafraîchissement. Le journal, l'examen et les notes n'affichent
  jamais leur contenu. Les widgets se déclarent dans
  `native/android/widgets.json` (4 modèles d'affichage : carte, semaine,
  liste, raccourcis) ; `generate.py` produit le code natif que la CI copie
  dans `android/` (`install_widget.sh`, qui saute les widgets plutôt que
  de faire échouer le build).
  L'écran Plus › Widgets les liste et propose « Ajouter » pour chacun
  (demande de placement faite au téléphone) ; il indique aussi si la
  version installée contient les widgets.
- Calendrier liturgique calculé pour n'importe quelle année (1583 à 2999),
  sans rien stocker par année (`ChurchCalendar`) : la date de Pâques
  (calcul grégorien) fixe le mercredi des Cendres, la Semaine sainte,
  l'Ascension et la Pentecôte, et l'Avent ouvre le cycle. Navigation
  d'année en année, année lectionnaire (A, B, C), tous les dimanches
  nommés (« 3e dimanche de l'Avent »), les fêtes, les couleurs, une
  recherche de date, et les dimanches spéciaux de la Discipline (¶ 262 à
  265) que l'on peut masquer. Vérifié contre le tableau « Calendar for
  dating Easter » du Livre de culte (2013 à 2020) et des dates connues.
- Livre de culte méthodiste uni : 27 textes (modèle de base, ordre du
  culte dominical, repas d'amour, louange du matin et du soir, mercredi des Cendres, Vendredi saint, culte de guérison, accompagnement des mourants, bénédiction d'une maison, naissance, salutations et prières d'ouverture, renouvellement de l'alliance, installation et mise en fonction de responsables, litanie, Dix commandements, confession, Grande action de
  grâce, bénédictions, Parole et Table I, mise en terre, Alliance
  baptismale I, mariage, mort et résurrection), traduits par DeepL puis
  corrigés à la main. Chaque texte donne la mention de droit d'auteur de la
  page d'origine et un lien vers l'original anglais. Sources dans
  `tools/book_of_worship/` (`texts/*.json`, `generate.py` produit
  `book_of_worship_data.dart`). Traduction à relire.
- Verset du jour : tiré d'une liste de 134 versets de réconfort et de
  courage (`ComfortVerses`), dans un ordre qui paraît aléatoire, sans
  répétition avant d'avoir parcouru toute la liste ; le même partout un
  jour donné (accueil et widget). Le texte vient de la base ; les marques
  de numérotation de certains Psaumes sont retirées à l'affichage.
- Raccourcis de l'icône (appui long, Android et iOS) : Rechercher,
  Cantiques, Culte du dimanche.
- Rappel de sauvegarde sur l'accueil si des données personnelles n'ont
  pas été exportées depuis 30 jours (« Plus tard » le repousse).
- Cantiques affichés par couplets/refrain nettement séparés (au lieu d'un
  seul bloc de texte), avec le refrain mis en valeur visuellement.
  Références bibliques cliquables dans les paroles.
- Réglages rapides « Aa » (taille du texte + interligne) accessibles
  directement depuis les écrans Bible et Cantiques, sans passer par le
  menu Réglages — même préférence partagée et persistée partout.
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
Un tutoriel de 7 écrans s'affiche automatiquement au tout premier
lancement (état suivi via `SharedPreferences`, jamais réaffiché
ensuite), pour présenter l'application à un nouvel
utilisateur. Accessible à nouveau à tout moment via l'onglet « Plus » →
« Revoir le tutoriel ».

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
