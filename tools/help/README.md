# Captures de l'aide

Les captures de `assets/help/` sont prises dans la vraie application (version web), en français et en
swahili, puis converties en WebP. Les positions des zones touchables sont relevées automatiquement
dans l'arbre d'accessibilité de Flutter : elles suivent donc le texte réel de chaque langue.

À refaire quand un écran montré dans l'aide change :

```bash
flutter build web --release
(cd build/web && python3 -m http.server 8099 &)
cd tools/help && NODE_PATH=$(npm root -g) node capture.js            # toutes les captures
cd tools/help && NODE_PATH=$(npm root -g) node capture.js fr:backup   # une seule
python3 -I tools/help/convert.py                                        # WebP + assets/help/shots.json
```

- `capture.js` : un « travail » par capture (navigation, puis zones). Pour en ajouter une, écrire son
  travail, l'ajouter à `only[lang]`, puis la citer dans `lib/features/help/data/help_content.dart`.
- Les textes des bulles sont dans `help_content.dart` (français et swahili).
- Un test (`test/help_shots_test.dart`) vérifie que chaque capture citée existe et que chaque zone a sa position.
