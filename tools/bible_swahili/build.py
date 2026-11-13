import re,sys,json,glob,subprocess
sys.path.insert(0,'.')
from survey import files
BOOKS=[("Mwanzo",50),("Kutoka",40),("Mambo ya Walawi",27),("Hesabu",36),("Torati",34),("Yoshua",24),("Waamuzi",21),("Ruth",4),("1 Samweli",31),("2 Samweli",24),("1 Wafalme",22),("2 Wafalme",25),("1 Nyakati",29),("2 Nyakati",36),("Ezra",10),("Nehemia",13),("Esta",10),("Ayubu",42),("Zaburi",150),("Mithali",31),("Mhubiri",12),("Wimbo wa Sulemani",8),("Isaya",66),("Yeremia",52),("Maombolezo",5),("Ezekieli",48),("Danieli",12),("Hosea",14),("Joeli",3),("Amosi",9),("Obadia",1),("Yona",4),("Mika",7),("Nahumu",3),("Habakuki",3),("Sefania",3),("Hagai",2),("Zekaria",14),("Malaki",4),("Mathayo",28),("Marko",16),("Luka",24),("Yohana",21),("Matendo",28),("Warumi",16),("1 Wakorintho",16),("2 Wakorintho",13),("Wagalatia",6),("Waefeso",6),("Wafilipi",4),("Wakolosai",4),("1 Wathesalonike",5),("2 Wathesalonike",3),("1 Timotheo",6),("2 Timotheo",4),("Tito",3),("Filemoni",1),("Wahebrania",13),("Yakobo",5),("1 Petro",5),("2 Petro",3),("1 Yohana",5),("2 Yohana",1),("3 Yohana",1),("Yuda",1),("Ufunuo",22)]
names={b for b,_ in BOOKS}
def words(pdf):
    out=subprocess.run(['pdftotext','-bbox',pdf,'-'],capture_output=True,text=True).stdout
    for pg in re.split(r'<page ',out)[1:]:
        yield [(float(a),float(b),float(c),float(d),w) for a,b,c,d,w in re.findall(r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)</word>',pg)]
def ordered(ws,mid=216):
    r=[]
    for lo,hi in ((0,mid),(mid,999)):
        col=sorted([w for w in ws if lo<=w[0]<hi],key=lambda w:(round((w[1]+w[3])/2/4),w[0]))
        # group lines by y tolerance
        lines=[];cur=[];y=None
        for w in col:
            cy=(w[1]+w[3])/2
            if y is None or abs(cy-y)>4:
                if cur: lines.append(cur)
                cur=[w];y=cy
            else: cur.append(w)
        if cur: lines.append(cur)
        for l in lines: r.append(sorted(l,key=lambda x:x[0]))
    return r
toks=[]  # (kind,text)
book=None
for fi,f in enumerate(files,1):
    for pi,ws in enumerate(words(f),1):
        if fi==10 and pi>=30: continue
        lines=ordered(ws)
        # footer
        foot=[l for l in lines if l[0][1]>=612 and len(l)>=2]
        ft=None
        for l in foot:
            t=' '.join(w[4] for w in l)
            m=re.match(r'^(\d+ )?(.+?)( \d+)?$',t)
            for b in names:
                if t==f'{b} {pi}' or re.fullmatch(rf'\d+ {re.escape(b)}',t) or re.fullmatch(rf'{re.escape(b)} \d+',t): ft=b
        if ft: book=ft
        hs={round(w[3]-w[1],1) for l in lines for w in l if w[1]<612}
        for l in lines:
            if l[0][1]>=612: continue
            hh=[round(w[3]-w[1],1) for w in l]
            if 9.0 not in hh and 16.8 not in hh: continue
            for w in l:
                wh=round(w[3]-w[1],1)
                if wh==16.8 and re.fullmatch(r'\d+',w[4]): toks.append(('C',w[4],book))
                elif wh in (9.0,): toks.append(('W',w[4],book))
                elif wh<7 and re.fullmatch(r'\d+',w[4]): toks.append(('V',w[4],book))
                else: toks.append(('X',w[4],book))
json.dump(toks,open('toks.json','w'))
print(len(toks),sum(1 for t in toks if t[0]=='C'))
import collections
print(collections.Counter(t[2] for t in toks if t[0]=='C'))
