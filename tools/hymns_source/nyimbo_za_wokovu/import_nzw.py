"""Importe « Nyimbo za Wokovu » (360 cantiques, Markdown) dans assets/db/app_data.db.

Usage : python3 import_nzw.py <fichier.md> <app_data.db>

- ajoute la colonne `hymnal` à `hymns` si elle manque ; les cantiques existants
  (Chants de Victoire) reçoivent 'CV', ceux-ci 'NZW' ;
- une strophe `**N.** texte` devient « N. texte » ; un paragraphe en italique
  (ou sans numéro) devient « Kiitikio » (refrain) suivi de ses lignes ;
- les sauts de ligne forcés du Markdown (deux espaces en fin de ligne) sont gardés
  comme lignes séparées ; le reste du texte reste tel que dans la source.
- relancer le script remplace les 360 cantiques NZW (idempotent).
"""
import re, sqlite3, sys

def parse(md):
    heads = list(re.finditer(r'^## (\d+)\. (.+)$', md, re.M))
    out = []
    for i, m in enumerate(heads):
        body = md[m.end(): heads[i + 1].start() if i + 1 < len(heads) else len(md)]
        paras = [p for p in re.split(r'\n\s*\n', body.strip()) if p.strip()]
        parts = []
        for p in paras:
            lines = [l.strip() for l in p.strip().split('\n') if l.strip()]
            first = lines[0]
            sm = re.match(r'^\*\*(\d+)\.\*\*\s*(.*)$', first)
            if sm:
                lines[0] = f"{sm.group(1)}. {sm.group(2)}".strip()
                parts.extend(lines)
            else:
                text = [l.strip('*').strip() if (l.startswith('*') or l.endswith('*')) else l for l in lines]
                parts.append('Kiitikio')
                parts.extend(t for t in text if t)
        title = m.group(2).strip().replace('’', "'")
        out.append((m.group(1), title, '\n\n'.join(t.replace('’', "'") for t in parts)))
    return out

if __name__ == '__main__':
    md = open(sys.argv[1], encoding='utf8').read()
    rows = parse(md)
    assert len(rows) == 360, len(rows)
    c = sqlite3.connect(sys.argv[2])
    cols = [r[1] for r in c.execute("pragma table_info(hymns)")]
    if 'hymnal' not in cols:
        c.execute("ALTER TABLE hymns ADD COLUMN hymnal TEXT")
    c.execute("UPDATE hymns SET hymnal='CV' WHERE hymnal IS NULL")
    c.execute("DELETE FROM hymns WHERE hymnal='NZW'")
    c.executemany("INSERT INTO hymns(number,title,key,lyrics,hymnal) VALUES(?,?,NULL,?,'NZW')", rows)
    c.execute("INSERT INTO hymns_fts(hymns_fts) VALUES('rebuild')")
    c.commit()
    print(c.execute("select hymnal,count(*) from hymns group by hymnal").fetchall())
