import re,sqlite3,json,sys
DB='/home/user/EMUCompagnon/assets/db/app_data.db'
c=sqlite3.connect(DB)
h={x['number']:x for x in json.load(open('hymns_docx.json'))}
num=re.compile(r'^(\d+)\\?\.\s*(.*)$'); keyl=re.compile(r'^\(.+\)$')
keys={n:(k or '') for n,k in c.execute('select number,key from hymns')}
rows=c.execute("select number,title,lyrics from hymns").fetchall()
def problems(ly):
    lines=[l.strip() for l in ly.split('\n\n') if l.strip()]
    labs=[int(num.match(l).group(1)) for l in lines if num.match(l)]
    first=[l for l in lines if not keyl.match(l)][:1]
    return (not labs) or labs!=list(range(1,len(labs)+1)) or not num.match(first[0]) or '\\' in ly
def words(s): return set(re.findall(r'\w+',s.lower().replace('’',"'")))
newkey={}
def rebuild(x):
    blocks=[[]]
    for t,b in x['body']:
        if t: blocks[-1].append(t)
        elif blocks[-1]: blocks.append([])
    blocks=[b for b in blocks if b]
    if blocks and re.fullmatch(r'(do|ré|re|mi|fa|sol|la|si)( (bémol|dièse))?',blocks[0][0].lower()):
        newkey[x['number']]=blocks[0][0].lower(); blocks[0]=blocks[0][1:]
        blocks=[b for b in blocks if b]
    out=[];exp=1
    # does a numbered marker 2 exist later?
    for i,b in enumerate(blocks):
        first=b[0]; m=re.match(r'^(\d{1,2})(\.|\s)\s*(\S.*)$',first)
        if m and int(m.group(1))==exp:
            b=[f"{m.group(1)}. {m.group(3)}"]+b[1:]; exp+=1
        elif exp==1 and i==0 and not re.match(r'^(Ch[oœ]+ur|Cœur|Refrain|Solo)',first,re.I) and any(re.match(r'^2(\.|\s)',bb[0]) for bb in blocks[1:]):
            b=['1. '+first]+b[1:]; exp=2
        out+=b
    s='\n\n'.join(out).replace('’',"'")
    s=re.sub(r'\\(?=[.!?*_()\[\]#-])','',s)
    if x['number']=='162':
        s=s.replace('1. (la\n\n)1. ','1. ')
        s=re.sub(r'\n\n(?=[a-zéèàç])',' ',s)
    s=re.sub(r'(^|\n\n)\. (?=\S)',lambda m: m.group(1)+'__N__. ',s)
    parts=s.split('\n\n');e=1
    for i,p in enumerate(parts):
        m=re.match(r'^(\d{1,2})\. ',p)
        if m and int(m.group(1))==e: e+=1
        elif p.startswith('__N__. '): parts[i]=f'{e}. '+p[7:]; e+=1
    return '\n\n'.join(parts)
cand=[];skip=[]
for n,t,ly in rows:
    if problems(ly):
        x=h.get(n)
        if not x: skip.append((n,'no docx'));continue
        new=rebuild(x)
        j=len(words(new)&words(ly))/max(1,len(words(new)|words(ly)))
        (cand if j>=0.85 else skip).append((n,round(j,2),new) if j>=0.85 else (n,round(j,2)))
print('rebuild',len(cand),'skip',skip)
json.dump(cand,open('cand.json','w'),ensure_ascii=False)
if len(sys.argv)>1:
    c.executemany("update hymns set lyrics=? where number=?",[(new,n) for n,j,new in cand])
    c.executemany("update hymns set key=? where number=? and (key is null or key='')",[(k,n) for n,k in newkey.items()])
    c.execute("update hymns set title=? where number='156' and title like '% cœur'",('Le service pour le Maître',))
    c.commit(); print('applied',newkey)
