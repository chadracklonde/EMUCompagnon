# Sources des cantiques « Chants de Victoire »

Fichiers fournis par le propriétaire du projet, conservés tels quels (ne pas supprimer) :

- `Chants-de-Victoire-CORRIGE.docx` : **source recommandée**. Une seule colonne, un paragraphe par vers, gras = numéro de couplet et refrain, titre en gras italique (« 152 Titre »), tonalité entre parenthèses.
- `Chants-de-Victoire-CORRIGE.txt` : extraction en deux colonnes entrelacées (type PDF) ; difficile à analyser, gardée pour mémoire.
- PDF : pas encore reçu.

Les cantiques de l'application sont dans `assets/db/app_data.db` (table `hymns`).

## Correction de la mise en forme (novembre 2026)

Scripts : `docx_parse.py` et `hymns.py` (lecture du .docx), `fix.py` (ajout du point après les numéros de couplet : « 1 Texte » devient « 1. Texte », « 1\. » devient « 1. »), `rebuild.py` (reconstruction à partir du .docx des cantiques dont la structure restait incorrecte). Seuls les cantiques mal affichés ont été modifiés. Le .docx s'arrête de façon fiable vers le n° 394 ; les n° 412 à 433 n'y figurent pas.

## Fichiers MIDI (novembre 2026)

`midi/` : les 121 fichiers MIDI fournis (`CV_<numéro>-polyinstru-<titre>.mid`, et `CV_311-mono-piano-…`), conservés tels quels. Ils ont été rendus en audio AAC mono 32 kbit/s avec FluidSynth et la banque de sons FluidR3_GM, puis publiés dans `hymn_audio/<numéro>.m4a`. La base (`hymns.audio_url`) ne garde que le chemin relatif ; l'adresse de base est `HymnAudio` (essaie `main`, puis la branche de travail) dans `lib/shared/widgets/hymn_audio_player.dart` (à passer sur `main` après la fusion de la PR). Trois fichiers (n° 102, 112 et 45a) avaient une piste de tempo tronquée (octet final manquant) : réparés par `midi_repair.py` avant le rendu.

## Nyimbo za Wokovu (novembre 2026)

`nyimbo_za_wokovu/Nyimbo_Za_Wokovu_360_Swahili.md` : 360 cantiques en swahili (texte original fourni par le propriétaire du projet), importés par `nyimbo_za_wokovu/import_nzw.py` dans `hymns` avec `hymnal = 'NZW'` (les Chants de Victoire sont `'CV'`). Le recueil affiché suit la langue : `Hymnals.forLocale` (`sw` → NZW, sinon CV). Les strophes `**N.**` deviennent « N. », les paragraphes en italique ou sans numéro deviennent « Kiitikio » (refrain). La source a fondu les vers d'une strophe en un seul paragraphe : seuls les sauts de ligne forcés (par exemple autour de `:/:`) ont été gardés. Aucune mention de droits n'est encore affichée dans l'application pour ce recueil.
