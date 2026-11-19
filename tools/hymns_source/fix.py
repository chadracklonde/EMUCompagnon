import re,sqlite3,json,sys
DB='/home/user/EMUCompagnon/assets/db/app_data.db'
c=sqlite3.connect(DB)
rows=c.execute("select id,number,lyrics from hymns").fetchall()
P=re.compile(r'^(\d{1,2})\s*\\?\.?\s*(?=\S)(.*)$',re.S)
def norm(ly):
    parts=ly.split('\n\n'); out=[];exp=1;changed=False
    for p in parts:
        s=p.strip()
        m=re.match(r'^(\d{1,2})(\\?\.|\s)\s*(\S.*)$',s,re.S)
        if m and int(m.group(1))==exp:
            new=f"{m.group(1)}. {m.group(3)}"
            if new!=p: changed=True
            out.append(new); exp+=1
        else: out.append(p)
    return '\n\n'.join(out),changed
ch=[];
for id_,n,ly in rows:
    new,chg=norm(ly)
    if chg: ch.append((id_,n,ly,new))
print('changed',len(ch))
for id_,n,o,nw in ch[:3]: print(n,repr(o[:90]),'->',repr(nw[:90]))
if len(sys.argv)>1:
    c.executemany("update hymns set lyrics=? where id=?",[(nw,id_) for id_,n,o,nw in ch])
    c.commit(); print('applied')
json.dump([c_[1] for c_ in ch],open('changed.json','w'))
