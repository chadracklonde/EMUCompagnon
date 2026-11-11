#!/usr/bin/env python3
"""Generates the home-screen widgets of native/android/widgets.json into the
generated android/ folder: one provider class, one provider-info file, one
description string and one manifest receiver per widget, plus the shared
renderer (EmuWidgets.kt) and a MainActivity that lets the app refresh them.

Usage: generate.py <android-dir> <package>
"""
import json
import os
import re
import sys

here = os.path.dirname(os.path.abspath(__file__))
android, pkg = sys.argv[1], sys.argv[2]
main = os.path.join(android, "app", "src", "main")
res = os.path.join(main, "res")
kotlin = os.path.join(main, "kotlin", *pkg.split("."))
os.makedirs(os.path.join(res, "xml"), exist_ok=True)
os.makedirs(os.path.join(res, "values"), exist_ok=True)
os.makedirs(kotlin, exist_ok=True)

widgets = json.load(open(os.path.join(here, "widgets.json"), encoding="utf-8"))

# Cells (width x height) targeted by each size; dp minimums for old launchers.
sizes = {
    "small": (2, 2, 110, 110),
    "medium": (4, 2, 250, 110),
    "tall": (4, 3, 250, 180),
    "wide": (4, 1, 250, 56),
}


def xml_escape(text):
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("'", "\\'")


strings = ['<?xml version="1.0" encoding="utf-8"?>', "<resources>"]
classes = ["VerseWidgetProvider"]
kt = [f"package {pkg}", "", "// Generated from native/android/widgets.json — do not edit.", ""]
receivers = []
for w in widgets:
    cols, rows, min_w, min_h = sizes[w["size"]]
    layout = "tpl_" + w["kind"]
    info = f'''<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:description="@string/emu_widget_{w["key"]}_desc"
    android:initialLayout="@layout/{layout}"
    android:minHeight="{min_h}dp"
    android:minWidth="{min_w}dp"
    android:resizeMode="horizontal|vertical"
    android:targetCellHeight="{rows}"
    android:targetCellWidth="{cols}"
    android:updatePeriodMillis="1800000"
    android:widgetCategory="home_screen" />
'''
    open(os.path.join(res, "xml", f"emu_widget_{w['key']}_info.xml"), "w", encoding="utf-8").write(info)
    strings.append(f'    <string name="emu_widget_{w["key"]}_desc">{xml_escape(w["desc"])}</string>')
    defaults = json.dumps(w["defaults"], ensure_ascii=False)
    kt.append(
        f'class {w["cls"]} : EmuWidgetProvider("{w["key"]}", "{w["kind"]}", '
        f'{str(w["dark"]).lower()}, """{defaults}""")'
    )
    classes.append(w["cls"])
    receivers.append(f'''        <receiver
            android:name=".{w["cls"]}"
            android:exported="false"
            android:label="{w["label"]}">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/emu_widget_{w["key"]}_info" />
        </receiver>''')
strings.append("</resources>")
kt.append("")
kt.append("object EmuWidgetRegistry {")
kt.append("    val providers: List<Class<*>> = listOf(")
for c in classes:
    kt.append(f"        {c}::class.java,")
kt.append("    )")
kt.append("")
kt.append("    val byKey: Map<String, Class<*>> = mapOf(")
kt.append('        "verse" to VerseWidgetProvider::class.java,')
for w in widgets:
    kt.append(f'        "{w["key"]}" to {w["cls"]}::class.java,')
kt.append("    )")
kt.append("}")
kt.append("")

open(os.path.join(res, "values", "emu_widgets_strings.xml"), "w", encoding="utf-8").write("\n".join(strings) + "\n")
open(os.path.join(kotlin, "EmuWidgetsGenerated.kt"), "w", encoding="utf-8").write("\n".join(kt))
core = open(os.path.join(here, "EmuWidgets.kt"), encoding="utf-8").read().replace("__PACKAGE__", pkg)
open(os.path.join(kotlin, "EmuWidgets.kt"), "w", encoding="utf-8").write(core)

# Manifest: replace the block between the markers (or add it).
manifest_path = os.path.join(main, "AndroidManifest.xml")
manifest = open(manifest_path, encoding="utf-8").read()
block = "        <!-- emu-widgets:start -->\n" + "\n".join(receivers) + "\n        <!-- emu-widgets:end -->\n    "
manifest = re.sub(r"        <!-- emu-widgets:start -->.*?<!-- emu-widgets:end -->\n    ", "", manifest, flags=re.S)
manifest = manifest.replace("</application>", block + "</application>", 1)
open(manifest_path, "w", encoding="utf-8").write(manifest)

# MainActivity: lets the app refresh the widgets right after writing their data.
# Only replaced when it is the untouched scaffold one.
for root, _dirs, files in os.walk(main):
    for name in files:
        if name != "MainActivity.kt":
            continue
        path = os.path.join(root, name)
        text = open(path, encoding="utf-8").read()
        if re.search(r"class MainActivity\s*:\s*FlutterActivity\(\)\s*$", text.strip()):
            activity = open(os.path.join(here, "MainActivity.kt"), encoding="utf-8").read().replace("__PACKAGE__", pkg)
            open(path, "w", encoding="utf-8").write(activity)
            print("MainActivity remplacée (rafraîchissement immédiat des widgets).")
        else:
            print("MainActivity inattendue : rafraîchissement immédiat des widgets ignoré.")
print(f"{len(widgets)} widgets générés.")
