#!/usr/bin/env bash
# Adds the "Verset du jour" home-screen widget to the generated android/
# folder (the CI recreates android/ with `flutter create`, so the widget
# lives here and is copied in). It never fails the build: if anything is
# not as expected the widget is skipped and the app is built without it.
#
# Usage: native/android/install_widget.sh [android-dir]
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ANDROID="${1:-android}"
MANIFEST="$ANDROID/app/src/main/AndroidManifest.xml"
GRADLE="$ANDROID/app/build.gradle.kts"
[ -f "$GRADLE" ] || GRADLE="$ANDROID/app/build.gradle"

PKG="$(grep -E 'namespace' "$GRADLE" 2>/dev/null | head -1 | sed -E "s/.*[\"']([^\"']+)[\"'].*/\1/")"
if [ -z "$PKG" ] || [ ! -f "$MANIFEST" ]; then
  echo "Widget Verset du jour ignoré : namespace ou manifeste introuvable."
  exit 0
fi

cp -r "$HERE/res/." "$ANDROID/app/src/main/res/"
KOTLIN_DIR="$ANDROID/app/src/main/kotlin/${PKG//.//}"
mkdir -p "$KOTLIN_DIR"
sed "s/__PACKAGE__/$PKG/" "$HERE/VerseWidgetProvider.kt" > "$KOTLIN_DIR/VerseWidgetProvider.kt"

if ! grep -q "VerseWidgetProvider" "$MANIFEST"; then
  python3 - "$MANIFEST" <<'PY'
import sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
receiver = '''
        <receiver
            android:name=".VerseWidgetProvider"
            android:exported="false"
            android:label="Verset du jour">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/verse_widget_info" />
        </receiver>
    '''
if "</application>" not in s:
    sys.exit("pas de </application>")
open(path, "w", encoding="utf-8").write(s.replace("</application>", receiver + "</application>", 1))
PY
  if [ $? -ne 0 ]; then
    echo "Widget Verset du jour ignoré : manifeste non modifiable."
    rm -f "$KOTLIN_DIR/VerseWidgetProvider.kt"
    exit 0
  fi
fi
# The other widgets (declared in widgets.json). Failing here must not break the build.
if command -v python3 >/dev/null 2>&1 && python3 "$HERE/generate.py" "$ANDROID" "$PKG"; then
  echo "Widgets supplémentaires installés."
else
  echo "Widgets supplémentaires ignorés : génération impossible."
fi
echo "Widget Verset du jour installé (paquet $PKG)."
