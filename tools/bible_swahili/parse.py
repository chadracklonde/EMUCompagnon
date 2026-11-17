import json,re,sys
sys.argv=['x']
src=open('build.py').read().split('def words')[0]
exec(src)
toks=json.load(open('toks.json'))
print('sum chapters',sum(n for _,n in BOOKS))
bi=-1;ch=0;v=0
out={}   # (bi,ch)->[(v,text)]
cur=None;anoms=[]
def flush(): pass
state={'txt':[]}
def put_verse():
    pass
verses={};xs=[]
curv=None
for k,t,_ in toks:
    if k=='C':
        c=int(t)
        if c==1 and (ch>=BOOKS[bi][1] if bi>=0 else True) or (bi<0):
            bi+=1; ch=1
        elif c==ch+1: ch=c
        else:
            anoms.append(('chapter',BOOKS[bi][0],ch,t)); 
            ch=c if c<=BOOKS[bi][1] else ch
        v=1; curv=(bi,ch,1); verses[curv]=[]
        continue
    if curv is None: continue
    if k=='X': xs.append(t); continue
    if k=='V' and int(t)==v+1:
        v+=1; curv=(bi,ch,v); verses[curv]=[]; continue
    verses[curv].append(t)
print('books',bi+1,'X',len(xs),xs[:15])
vs=[k for k in verses if True]
import collections
cnt=collections.Counter(k[0] for k in verses)
print('verses',len(verses))
json.dump({f'{b}|{c}|{v}':' '.join(x) for (b,c,v),x in verses.items()},open('verses.json','w'),ensure_ascii=False)
print(anoms[:20])
# chapter coverage
for i,(n,c) in enumerate(BOOKS):
    got=len({k[1] for k in verses if k[0]==i})
    if got!=c: print('MISMATCH',n,c,got)
