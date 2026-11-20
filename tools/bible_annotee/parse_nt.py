import re, json, sys, html, os, glob
RAW, OUT = sys.argv[1], sys.argv[2]
files = "Matthieu Marc Luc Jean Actes Romains 1Corinthiens 2Corinthiens Galates Ephesiens Philippiens Colossiens 1Thessaloniciens 2Thessaloniciens 1Timothee 2Timothee Tite Philemon Hebreux Jacques 1Pierre 2Pierre 1Jean 2Jean 3Jean Jude Apocalypse".split()
# noms utilisés par l'application (base Louis Segond)
names = ["Matthieu","Marc","Luc","Jean","Actes","Romains","1 Corinthiens","2 Corinthiens","Galates","Ephésiens","Philippiens","Colossiens","1 Thessaloniciens","2 Thessaloniciens","1 Timothée","2 Timothée","Tite","Philémon","Hébreux","Jacques","1 Pierre","2 Pierre","1 Jean","2 Jean","3 Jean","Jude","Révélation"]
def clean(s):
    s = re.sub(r'<br\s*/?>', ' ', s)
    s = re.sub(r'<[^>]+>', '', s)
    s = html.unescape(s).replace('\xa0', ' ')
    return re.sub(r'\s+', ' ', s).strip()
out, problems = [], []
for f, name in zip(files, names):
    pages = sorted(glob.glob(f"{RAW}/{f}_nta_*.html"), key=lambda p: int(re.findall(r'_nta_(\d+)\.html', p)[0]))
    for p in pages:
        t = open(p, 'rb').read().decode('cp1252')
        h = re.search(r'<h5>(.*?)</h5>', t, re.S)
        head = re.sub(r'\s+', ' ', html.unescape(re.sub('<[^>]+>', '', h.group(1))).replace('\xa0', ' ')) if h else ''
        m = re.search(r'(\d+)\.(\d+)\s*à\s*(\d+)\.(\d+)', head)
        if not m:
            m1 = re.search(r'(\d+)\.(\d+)', head)
            if not m1: problems.append(f"entête illisible {p} {head!r}"); continue
            ch = int(m1.group(1))
        else:
            ch = int(m.group(1))
        cells = re.findall(r'<td class="trd">(.*?)</td>', t, re.S)
        if not cells: problems.append(f"pas de texte {p}"); continue
        body = cells[0]
        parts = re.split(r'<font\s+class="v">(.*?)</font>', body, flags=re.S)
        prev = None
        for i in range(1, len(parts), 2):
            label = clean(parts[i]).rstrip('.')
            mm = re.match(r'(\d+)', label)
            if not mm: problems.append(f"marqueur {label!r} {p}"); continue
            v = int(mm.group(1))
            if prev is not None and v < prev: ch += 1
            prev = v
            out.append({"book": name, "chapter": ch, "verse": v, "text": clean(parts[i + 1])})
json.dump(out, open(OUT, 'w', encoding='utf8'), ensure_ascii=False, indent=0)
print(len(out), "versets;", len(problems), "problèmes")
for x in problems[:25]: print(" ", x)
