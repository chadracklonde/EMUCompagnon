import json,re,sqlite3
paras=json.load(open('paras.json'))
H=re.compile(r'^(\d+[a-z]?)\s+(.+)$')
hymns=[];cur=None
def blanks_before(i):
    n=0
    while i-1-n>=396 and not paras[i-1-n][0]: n+=1
    return n
last=0
for i,(t,b,it) in enumerate(paras[396:],396):
    if b and t:
        m=H.match(t)
        if m and (it or blanks_before(i)>=2):
            n=int(re.sub(r'\D','',m.group(1)))
            if (it and cur is None) or (n>=last and n<=last+3 and (cur is None or cur['body'])):
                cur={'number':m.group(1),'title':m.group(2),'key':None,'body':[]};hymns.append(cur);last=n;continue
        if cur is not None and not cur['body'] and cur['key'] is None and it:
            cur['title']+=' '+t; continue
    if cur is None: continue
    if cur['key'] is None and not cur['body'] and re.match(r'^\(.+\)$',t):
        cur['key']=t[1:-1]; continue
    cur['body'].append((t,b))
print(len(hymns))
json.dump(hymns,open('hymns_docx.json','w'),ensure_ascii=False)
c=sqlite3.connect('/home/user/EMUCompagnon/assets/db/app_data.db')
db={r[0]:r for r in c.execute("select number,title,key,lyrics from hymns")}
dn=set(db); xn={h['number'] for h in hymns}
print('only db',sorted(dn-xn,key=lambda s:(int(re.sub(r'\D','',s)),s))[:20],'only docx',sorted(xn-dn)[:20], len(dn),len(xn))
