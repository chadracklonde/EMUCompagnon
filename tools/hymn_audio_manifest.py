"""Génère assets/hymn_audio_manifest.json : la liste des enregistrements de hymn_audio/ avec leur taille.

L'application s'en sert pour le pack d'écoute hors ligne : nombre de fichiers, taille totale,
et vérification de chaque fichier téléchargé (taille exacte). À relancer quand on ajoute ou
remplace un enregistrement :  python3 tools/hymn_audio_manifest.py
"""
import json, os, re
root = os.path.join(os.path.dirname(__file__), '..')
audio = os.path.join(root, 'hymn_audio')
files = sorted(os.listdir(audio), key=lambda n: (int(re.match(r'\d+', n).group()), n))
items = [{'name': f, 'size': os.path.getsize(os.path.join(audio, f))} for f in files if f.endswith('.m4a')]
out = os.path.join(root, 'assets', 'hymn_audio_manifest.json')
json.dump({'files': items}, open(out, 'w'), indent=1)
print(len(items), 'fichiers,', sum(i['size'] for i in items), 'octets ->', out)
