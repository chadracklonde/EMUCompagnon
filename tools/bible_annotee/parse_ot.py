import re, json, sys, html, os
RAW, OUT = sys.argv[1], sys.argv[2]
abr = "gen exo lev nom deu josue juges ruth 1samuel 2samuel 1rois 2rois 1chroniques 2chroniques esdras nehemie esther job proverbes ecclesiaste cantique psaumes esaie jeremie lamentations ezechiel daniel osee joel amos abdias jonas michee nahum habakuk sophonie aggee zacharie malachie".split()
names = ["Genèse","Exode","Lévitique","Nombres","Deutéronome","Josué","Juges","Ruth","1 Samuel","2 Samuel","1 Rois","2 Rois","1 Chroniques","2 Chroniques","Esdras","Néhémie","Esther","Job","Proverbes","Ecclésiaste","Cantique","Psaumes","Esaïe","Jérémie","Lamentations","Ezéchiel","Daniel","Osée","Joël","Amos","Abdias","Jonas","Michée","Nahum","Habacuc","Sophonie","Aggée","Zacharie","Malachie"]
chap = [50,40,27,36,34,24,21,4,31,24,22,25,29,36,10,13,10,42,31,12,8,150,66,52,5,48,12,14,3,9,1,4,7,3,3,3,2,14,4]
row = re.compile(r'<div class="num">\s*(\d+)\s*</div></td>\s*<td><div class="trd">(.*?)</div></td>', re.S)
def clean(s):
    s = re.sub(r'<br\s*/?>', '\n', s)
    s = re.sub(r'<[^>]+>', '', s)
    s = html.unescape(s).replace('\xa0', ' ')
    return re.sub(r'[ \t]+', ' ', s).strip()
out, problems = [], []
for a, name, n in zip(abr, names, chap):
    for c in range(1, n + 1):
        p = f"{RAW}/{a}{c}_t.html"
        if not os.path.exists(p):
            problems.append(f"manquant {a} {c}"); continue
        t = open(p, 'rb').read().decode('cp1252')
        verses = row.findall(t)
        if not verses: problems.append(f"aucun verset {a} {c}")
        for v, txt in verses:
            out.append({"book": name, "chapter": c, "verse": int(v), "text": clean(txt)})
json.dump(out, open(OUT, 'w', encoding='utf8'), ensure_ascii=False, indent=0)
print(len(out), "versets;", len(problems), "problèmes")
for x in problems[:20]: print(" ", x)
