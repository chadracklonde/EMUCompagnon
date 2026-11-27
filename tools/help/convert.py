"""Convertit les captures de tools/help/out en WebP et écrit assets/help/shots.json."""
import json, os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
m = json.load(open(os.path.join(HERE, 'out', 'manifest.json')))
total = 0
for lang, shots in m.items():
    os.makedirs(os.path.join(ROOT, 'assets', 'help', lang), exist_ok=True)
    for sid in shots:
        out = os.path.join(ROOT, 'assets', 'help', lang, sid + '.webp')
        Image.open(os.path.join(HERE, 'out', f'{lang}_{sid}.png')).convert('RGB').save(out, 'WEBP', quality=82, method=6)
        total += os.path.getsize(out)
json.dump(m, open(os.path.join(ROOT, 'assets', 'help', 'shots.json'), 'w'), separators=(',', ':'))
print(f'{sum(len(v) for v in m.values())} captures, {total // 1024} Ko')
