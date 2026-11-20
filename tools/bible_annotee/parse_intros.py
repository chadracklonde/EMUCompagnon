"""Extrait les INTRODUCTIONS de livres de la Bible annotée (archives de Claude Royère).

Usage : python3 -I parse_intros.py <dossier intros_ba> <dossier intros_nta> <sortie.json>

Sortie : {"intros": [{id, source, title, html}], "books": [{book, intro_id, position}]}
Balises conservées (mêmes que les notes) : p, i, b, h (intertitre), ref, ul, li, br.
Les appels de note de bas de page deviennent des exposants Unicode (¹ ² ³…) et les notes
sont rassemblées à la fin, sous un intertitre « Notes ».
"""
import glob, html, json, os, re, sys

BA_DIR, NTA_DIR, OUT = sys.argv[1], sys.argv[2], sys.argv[3]

SUP = str.maketrans("0123456789", "⁰¹²³⁴⁵⁶⁷⁸⁹")

# fichier → (identifiant, source, titre court affiché, livres concernés, dans l'ordre d'affichage)
# Les noms de livres sont ceux de l'application (voir parse_notes.py).
AT = [
    ("intro_ba", "Introduction à la Bible", ["Genèse"]),
    ("intro_pentateuque", "Introduction au Pentateuque", ["Genèse"]),
    ("creation", "Étude sur la Création (F. Godet)", ["Genèse"]),
    ("conclusion_pentateuque", "Conclusions sur le Pentateuque", ["Deutéronome"]),
    ("intro_historiques", "Introduction aux livres historiques", ["Josué"]),
    ("intro_josue", "Introduction à Josué", ["Josué"]),
    ("intro_juges", "Introduction aux Juges", ["Juges"]),
    ("intro_ruth", "Introduction à Ruth", ["Ruth"]),
    ("intro_samuel", "Introduction aux livres de Samuel", ["1 Samuel", "2 Samuel"]),
    ("intro_rois", "Introduction aux livres des Rois", ["1 Rois", "2 Rois"]),
    ("intro_chroniques", "Introduction aux Chroniques", ["1 Chroniques", "2 Chroniques"]),
    ("intro_esdras", "Introduction à Esdras et Néhémie", ["Esdras", "Néhémie"]),
    ("intro_esther", "Introduction à Esther", ["Esther"]),
    ("intro_hagiographes", "Introduction aux Hagiographes", ["Job"]),
    ("intro_job", "Introduction à Job", ["Job"]),
    ("etude_job", "Le livre de Job (étude)", ["Job"]),
    ("intro_psaumes", "Introduction aux Psaumes", ["Psaumes"]),
    ("intro_proverbes", "Introduction aux Proverbes", ["Proverbes"]),
    ("intro_ecclesiaste", "Introduction à l'Ecclésiaste", ["Ecclésiaste"]),
    ("intro_cantique", "Introduction au Cantique des cantiques", ["Cantique"]),
    ("etude_cantique", "Étude sur le Cantique des cantiques", ["Cantique"]),
    ("intro_prophetes", "Introduction aux prophètes", ["Esaïe"]),
    ("intro_esaie", "Introduction à Esaïe", ["Esaïe"]),
    ("intro_jeremie", "Introduction à Jérémie", ["Jérémie"]),
    ("intro_lamentations", "Introduction aux Lamentations", ["Lamentations"]),
    ("intro_ezechiel", "Introduction à Ezéchiel", ["Ezéchiel"]),
    ("intro_daniel", "Introduction à Daniel", ["Daniel"]),
    ("intro_osee", "Introduction à Osée", ["Osée"]),
    ("intro_joel", "Introduction à Joël", ["Joël"]),
    ("intro_amos", "Introduction à Amos", ["Amos"]),
    ("intro_abdias", "Introduction à Abdias", ["Abdias"]),
    ("intro_jonas", "Introduction à Jonas", ["Jonas"]),
    ("intro_michee", "Introduction à Michée", ["Michée"]),
    ("intro_nahum", "Introduction à Nahum", ["Nahum"]),
    ("intro_habakuk", "Introduction à Habacuc", ["Habacuc"]),
    ("intro_sophonie", "Introduction à Sophonie", ["Sophonie"]),
    ("intro_aggee", "Introduction à Aggée", ["Aggée"]),
    ("intro_zacharie", "Introduction à Zacharie", ["Zacharie"]),
    ("intro_malachie", "Introduction à Malachie", ["Malachie"]),
]
NT = [
    ("intro_Matthieu", "Introduction à Matthieu", ["Matthieu"]),
    ("intro_Marc", "Introduction à Marc", ["Marc"]),
    ("intro_Luc", "Introduction à Luc", ["Luc"]),
    ("intro_Jean", "Introduction à Jean", ["Jean"]),
    ("intro_Actes", "Introduction aux Actes", ["Actes"]),
    ("intro_Paul", "Introduction générale aux épîtres de Paul", ["Romains"]),
    ("intro_Romains", "Introduction à l'épître aux Romains", ["Romains"]),
    ("intro_1Corinthiens", "Introduction à la 1re épître aux Corinthiens", ["1 Corinthiens"]),
    ("intro_2Corinthiens", "Introduction à la 2e épître aux Corinthiens", ["2 Corinthiens"]),
    ("intro_Galates", "Introduction à l'épître aux Galates", ["Galates"]),
    ("intro_Ephesiens", "Introduction à l'épître aux Ephésiens", ["Ephésiens"]),
    ("intro_Philippiens", "Introduction à l'épître aux Philippiens", ["Philippiens"]),
    ("intro_Colossiens", "Introduction à l'épître aux Colossiens", ["Colossiens"]),
    ("intro_1Thessaloniciens", "Introduction à la 1re épître aux Thessaloniciens", ["1 Thessaloniciens"]),
    ("intro_2Thessaloniciens", "Introduction à la 2e épître aux Thessaloniciens", ["2 Thessaloniciens"]),
    ("intro_1Timothee", "Introduction aux épîtres pastorales et à 1 Timothée", ["1 Timothée"]),
    ("intro_2Timothee", "Introduction à la 2e épître à Timothée", ["2 Timothée"]),
    ("intro_Tite", "Introduction à l'épître à Tite", ["Tite"]),
    ("intro_Philemon", "Introduction à l'épître à Philémon", ["Philémon"]),
    ("intro_Hebreux", "Introduction à l'épître aux Hébreux", ["Hébreux"]),
    ("intro_Jacques", "Introduction à l'épître de Jacques", ["Jacques"]),
    ("intro_1Pierre", "Introduction à la 1re épître de Pierre", ["1 Pierre"]),
    ("intro_2Pierre", "Introduction à la 2e épître de Pierre", ["2 Pierre"]),
    ("intro_1Jean", "Introduction à la 1re épître de Jean", ["1 Jean"]),
    ("intro_2Jean", "Introduction aux 2e et 3e épîtres de Jean", ["2 Jean", "3 Jean"]),
    ("intro_Jude", "Introduction à l'épître de Jude", ["Jude"]),
    ("intro_Apocalypse", "Introduction à l'Apocalypse", ["Révélation"]),
]

problems = []
# études : (motif du premier bloc conservé, n° de l'occurrence)
START = {'creation': (r'introduction', 2), 'etude_job': (r'introduction', 1), 'etude_cantique': (r'introduction', 1)}


def body_of(t, fname):
    """Isole la zone de lecture : après le premier titre, avant le pied de page."""
    t = re.sub(r'<script.*?</script>', '', t, flags=re.S | re.I)
    t = re.sub(r'<!--.*?-->', '', t, flags=re.S)
    m = re.search(r'<body[^>]*>', t, re.I)
    if m:
        t = t[m.end():]
    t = re.sub(r'</body>.*', '', t, flags=re.S | re.I)
    return t


def convert(t):
    """Jetons HTML → liste de blocs [(type, contenu_inline)], type ∈ p, h, li."""
    blocks = []          # (kind, inline_html)
    cur = []             # inline en cours
    kind = 'p'
    stack = []           # balises inline ouvertes : i, b, ref
    in_footnote_list = False
    foot_items = []      # [(num, inline)]
    foot_cur = None
    skip_depth = 0       # <a name=text…> : on garde le texte (n° d'appel)

    def flush():
        nonlocal cur, kind
        s = ''.join(cur)
        # ferme les balises restées ouvertes dans ce bloc
        s = s.strip()
        if s and re.sub(r'<[^>]+>|\s', '', s):
            blocks.append((kind, s))
        cur = []
        kind = 'p'

    def put(x):
        (foot_cur if foot_cur is not None else cur).append(x)

    toks = re.split(r'(<[^>]+>)', t)
    sup_open = False
    for tok in toks:
        if not tok.startswith('<'):
            tok = tok.replace('&lt;&lt;', '«\u00a0').replace('&gt;&gt;', '\u00a0»')
            tx = html.unescape(tok)
            tx = re.sub(r'&(?=\S)', ' ', tx)   # un « & » égaré dans la source (Romains)
            tx = re.sub(r'[ \t\r\n]+', ' ', tx)
            if sup_open:
                tx = tx.translate(SUP)
            put(tx)
            continue
        m = re.match(r'<\s*(/?)\s*([a-zA-Z0-9]+)([^>]*)>', tok)
        if not m:
            continue
        close, tag, attrs = m.group(1) == '/', m.group(2).lower(), m.group(3)
        if tag == 'font':
            cls = re.search(r'class\s*=\s*"?(\w+)', attrs, re.I)
            if not close:
                c = cls.group(1).lower() if cls else ''
                if c in ('sm', 'ref'):
                    put('<ref>'); stack.append('ref')
                elif c in ('bb', 'bib'):
                    put('<b>'); stack.append('b')
                elif c in ('auteur', 'cit', 'eph'):
                    put('<i>'); stack.append('i')
                else:
                    stack.append(None)
            else:
                if stack:
                    x = stack.pop()
                    if x:
                        put(f'</{x}>')
            continue
        if tag in ('em', 'i', 'cite'):
            if not close:
                put('<i>'); stack.append('i')
            else:
                # ne ferme que si la dernière balise inline ouverte est i
                for k in range(len(stack) - 1, -1, -1):
                    if stack[k] == 'i':
                        # ferme les balises intermédiaires proprement
                        while len(stack) - 1 > k:
                            y = stack.pop()
                            if y: put(f'</{y}>')
                        stack.pop(); put('</i>'); break
            continue
        if tag in ('b', 'strong'):
            if not close:
                put('<b>'); stack.append('b')
            else:
                for k in range(len(stack) - 1, -1, -1):
                    if stack[k] == 'b':
                        while len(stack) - 1 > k:
                            y = stack.pop()
                            if y: put(f'</{y}>')
                        stack.pop(); put('</b>'); break
            continue
        if tag == 'sup':
            sup_open = not close
            continue
        if tag in ('h1', 'h2', 'h3', 'h4', 'big'):
            flush() if not close or tag != 'big' else None
            if not close:
                kind = 'h'
            else:
                flush()
            continue
        if tag in ('p', 'blockquote', 'div', 'tr', 'table', 'dl', 'hr', 'ol', 'ul', 'caption'):
            flush()
            continue
        if tag == 'td':
            flush()
            continue
        if tag == 'li':
            if not close:
                flush(); kind = 'li'
            else:
                flush()
            continue
        if tag == 'dt':
            # liste de notes : <dt><a name=noteN>N</a><dd>texte
            if foot_cur is not None:
                foot_items.append(''.join(foot_cur))
            foot_cur = []
            in_footnote_list = True
            continue
        if tag == 'dd':
            continue
        if tag == 'br':
            # deux <br> consécutifs = nouveau paragraphe ; un seul : saut de ligne simple
            if cur and cur[-1] == '<br>':
                cur.pop()
                flush()
            else:
                put('<br>')
            continue
        # autres balises ignorées (a, table…)
    if foot_cur is not None:
        foot_items.append(''.join(foot_cur))
    flush()
    return blocks, foot_items


def balance(s):
    """Referme les balises restées ouvertes et retire les fermetures sans ouverture."""
    out, stack = [], []
    for tok in re.split(r'(</?(?:i|b|ref)>)', s):
        m = re.fullmatch(r'<(/?)(i|b|ref)>', tok)
        if not m:
            out.append(tok); continue
        if not m.group(1):
            stack.append(m.group(2)); out.append(tok)
        elif m.group(2) in stack:
            while stack[-1] != m.group(2):
                out.append(f'</{stack.pop()}>')
            stack.pop(); out.append(tok)
    while stack:
        out.append(f'</{stack.pop()}>')
    return ''.join(out)


def clean_inline(s):
    s = balance(s)
    s = re.sub(r'(<br>\s*)+$', '', s)
    s = re.sub(r'^(\s*<br>)+', '', s)
    s = re.sub(r'<(i|b|ref)>\s*</\1>', '', s)
    s = re.sub(r'\s+', ' ', s)
    return s.strip()


def esc(s):
    return s


def to_html(blocks, foot):
    out, ul = [], False
    for kind, s in blocks:
        s = clean_inline(s)
        if not s:
            continue
        if kind == 'li':
            if not ul:
                out.append('<ul>'); ul = True
            out.append(f'<li>{s}</li>')
            continue
        if ul:
            out.append('</ul>'); ul = False
        out.append(f'<h>{s}</h>' if kind == 'h' else f'<p>{s}</p>')
    if ul:
        out.append('</ul>')
    if foot:
        out.append('<h>Notes</h>')
        for i, f in enumerate(foot, 1):
            f = clean_inline(f)
            # le numéro d'ancre est dans le texte : on le remplace par l'exposant normalisé
            f = re.sub(r'^\d+\s*', '', f)
            out.append(f'<p>{str(i).translate(SUP)} {f}</p>')
    return ''.join(out)


def heading_of(t):
    m = re.search(r'<h1[^>]*>(.*?)</h1>', t, re.S | re.I)
    return re.sub(r'<[^>]+>', '', m.group(1)).strip() if m else ''


def process(d, entries, source):
    intros = []
    for fid, title, books in entries:
        p = os.path.join(d, fid + '.html')
        if not os.path.exists(p):
            problems.append(f'manquant {p}')
            continue
        t = open(p, 'rb').read().decode('cp1252')
        blocks, foot = convert(body_of(t, fid))
        def plain(b):
            return re.sub(r'<[^>]+>|\s+', ' ', b[1]).strip()
        # études : on saute le sommaire et l'index qui précèdent le texte
        if fid in START:
            seen = 0
            for k, b in enumerate(blocks):
                if re.fullmatch(START[fid][0], plain(b), re.I):
                    seen += 1
                    if seen == START[fid][1]:
                        blocks = blocks[k:]
                        break
            else:
                problems.append(f'début introuvable {fid}')
        # navigation d'origine (index, sommaire, retour en haut) et titre répété de la page
        blocks = [b for b in blocks if not re.fullmatch(r'(index|sommaire|début|retour.*|haut de page)', plain(b), re.I)]
        while len(blocks) > 1 and len(plain(blocks[0])) < 100 and re.match(
                r'(introduction|préface|[ée]pîtres?\b|[ée]vangile|les actes|apocalypse|bible annot[ée]e|la bible( annot[ée]e)?$|le livre de job$|[ée]tude sur le cantique)',
                plain(blocks[0]), re.I) and fid not in START:
            blocks.pop(0)
        h = to_html(blocks, foot)
        intros.append({"id": fid, "source": source, "title": title, "books": books, "html": h})
    return intros


intros = process(BA_DIR, AT, 'AT') + process(NTA_DIR, NT, 'NT')
books, pos = [], {}
for it in intros:
    for b in it['books']:
        n = pos.get(b, 0)
        pos[b] = n + 1
        books.append({"book": b, "intro_id": it['id'], "position": n})
for it in intros:
    del it['books']
json.dump({"intros": intros, "books": books}, open(OUT, 'w', encoding='utf8'), ensure_ascii=False, separators=(',', ':'))
print(len(intros), "introductions;", len(books), "liens livre→introduction;",
      sum(len(i['html']) for i in intros) // 1024, "Ko;", len(problems), "problèmes")
for x in problems: print(' ', x)
