"""Extrait les NOTES de la Bible annotée (texte des notes seul, balises simplifiées).

Usage : python3 -I parse_notes.py <dossier_pages_AT_c> <dossier_pages_NT> <sortie.json>
Balises conservées : p, i (italique), b (mot commenté), h (titre), ref (référence biblique), ul/li, br.
"""
import re, json, sys, html, glob, os
OT_DIR, NT_DIR, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
ot_abr = "gen exo lev nom deu josue juges ruth 1samuel 2samuel 1rois 2rois 1chroniques 2chroniques esdras nehemie esther job proverbes ecclesiaste cantique psaumes esaie jeremie lamentations ezechiel daniel osee joel amos abdias jonas michee nahum habakuk sophonie aggee zacharie malachie".split()
ot_names = ["Genèse","Exode","Lévitique","Nombres","Deutéronome","Josué","Juges","Ruth","1 Samuel","2 Samuel","1 Rois","2 Rois","1 Chroniques","2 Chroniques","Esdras","Néhémie","Esther","Job","Proverbes","Ecclésiaste","Cantique","Psaumes","Esaïe","Jérémie","Lamentations","Ezéchiel","Daniel","Osée","Joël","Amos","Abdias","Jonas","Michée","Nahum","Habacuc","Sophonie","Aggée","Zacharie","Malachie"]
ot_chap = [50,40,27,36,34,24,21,4,31,24,22,25,29,36,10,13,10,42,31,12,8,150,66,52,5,48,12,14,3,9,1,4,7,3,3,3,2,14,4]
nt_files = "Matthieu Marc Luc Jean Actes Romains 1Corinthiens 2Corinthiens Galates Ephesiens Philippiens Colossiens 1Thessaloniciens 2Thessaloniciens 1Timothee 2Timothee Tite Philemon Hebreux Jacques 1Pierre 2Pierre 1Jean 2Jean 3Jean Jude Apocalypse".split()
nt_names = ["Matthieu","Marc","Luc","Jean","Actes","Romains","1 Corinthiens","2 Corinthiens","Galates","Ephésiens","Philippiens","Colossiens","1 Thessaloniciens","2 Thessaloniciens","1 Timothée","2 Timothée","Tite","Philémon","Hébreux","Jacques","1 Pierre","2 Pierre","1 Jean","2 Jean","3 Jean","Jude","Révélation"]
KEEP = {"p","i","b","h","ref","ul","li","br"}
def simplify(frag):
    s = frag
    s = re.sub(r'<font\s+class\s*=\s*"?(bib)"?\s*>', '<b>', s, flags=re.I)
    s = re.sub(r'<font\s+class\s*=\s*"?(eph|cit|cb)"?\s*>', '<i>', s, flags=re.I)
    s = re.sub(r'<font\s+class\s*=\s*"?(ref)"?\s*>', '<ref>', s, flags=re.I)
    s = re.sub(r'<font\s+class\s*=\s*"?(mul)"?\s*>', '<h>', s, flags=re.I)
    # fermeture : on remplace </font> selon la pile
    out, stack = [], []
    for tok in re.split(r'(<[^>]+>)', s):
        if not tok.startswith('<'):
            out.append(tok); continue
        m = re.match(r'<\s*(/?)\s*([a-zA-Z0-9]+)', tok)
        if not m: continue
        close, tag = m.group(1) == '/', m.group(2).lower()
        if tag == 'font':
            if close and stack and stack[-1] in ('b','i','ref','h'): out.append(f'</{stack.pop()}>')
            elif close: pass
            else: stack.append('x')  # font inconnue : ignorée
            if not close and stack and stack[-1]=='x': stack.pop(); stack.append('x')
            continue
        tag = {'em':'i','small':'ref','big':'h','strong':'b'}.get(tag, tag)
        if tag not in KEEP: continue
        if tag == 'br': out.append('<br>'); continue
        if close:
            # ne ferme que si ouverte
            if tag in stack:
                while stack and stack[-1] != tag:
                    x = stack.pop()
                    if x != 'x': out.append(f'</{x}>')
                stack.pop(); out.append(f'</{tag}>')
        else:
            stack.append(tag); out.append(f'<{tag}>')
    while stack:
        x = stack.pop()
        if x != 'x': out.append(f'</{x}>')
    s = ''.join(out)
    s = html.unescape(s).replace('\xa0', ' ')
    s = re.sub(r'[ \t\r\f\v]+', ' ', s)
    s = re.sub(r'\s*\n\s*', ' ', s)
    s = re.sub(r'<p>\s*</p>', '', s)
    s = re.sub(r'\s*(</?(?:p|ul|li)>)\s*', r'\1', s)
    s = s.strip()
    # le texte qui précède le premier paragraphe est mis dans son propre paragraphe
    if s and not s.startswith(('<p>', '<ul>')):
        k = s.find('<p>')
        s = f'<p>{s}</p>' if k < 0 else f'<p>{s[:k]}</p>{s[k:]}'
    return s
notes, problems = [], []
# --- Ancien Testament : une page de notes par chapitre
for a, name, n in zip(ot_abr, ot_names, ot_chap):
    for c in range(1, n + 1):
        p = f"{OT_DIR}/{a}{c}_c.html"
        if not os.path.exists(p): problems.append(f"manquant {a} {c}"); continue
        t = open(p, 'rb').read().decode('cp1252')
        for numhtml, body in re.findall(r'<div class\s*=\s*"num"\s*>(.*?)</div></td>\s*<td[^>]*>\s*<div class\s*=\s*"def"\s*>(.*?)</div></td>', t, re.S):
            num = re.sub(r'<[^>]+>', '', numhtml).strip()
            notes.append({"book": name, "chapter": c, "verse": int(num) if num.isdigit() else 0, "source": "AT", "html": simplify(body)})
# --- Nouveau Testament : notes insérées dans les pages de texte
for f, name in zip(nt_files, nt_names):
    pages = sorted(glob.glob(f"{NT_DIR}/{f}_nta_*.html"), key=lambda p: int(re.findall(r'_nta_(\d+)\.html', p)[0]))
    for p in pages:
        t = open(p, 'rb').read().decode('cp1252')
        i = t.find('<table class="notes"')
        if i < 0: problems.append(f"pas de notes {p}"); continue
        rows = re.findall(r'<tr[^>]*>(.*?)</tr>', t[i:], re.S)
        cur = None
        for r in rows:
            m = re.search(r'<font class="cp">(\d+)</font>\s*<font class="vs">\.?([^<]*)</font>', r)
            if m:
                v = re.match(r'(\d+)', m.group(2).strip())
                cur = (int(m.group(1)), int(v.group(1)) if v else 0)
                continue
            mn = re.search(r'<td class="nt">(.*?)</td>', r, re.S)
            if mn and cur:
                notes.append({"book": name, "chapter": cur[0], "verse": cur[1], "source": "NT", "html": simplify(mn.group(1))})
            elif mn:
                notes.append({"book": name, "chapter": 0, "verse": 0, "source": "NT", "html": simplify(mn.group(1))})
json.dump(notes, open(OUT, 'w', encoding='utf8'), ensure_ascii=False, separators=(',', ':'))
print(len(notes), "notes;", len(problems), "problèmes")
for x in problems[:20]: print(" ", x)
