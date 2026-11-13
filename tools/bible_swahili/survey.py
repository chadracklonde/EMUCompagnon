import glob,collections,sys
sys.path.insert(0,'.')
from pg import pages,page_text
U='/root/.claude/uploads/2f27ca2d-d917-54ea-97ac-3fd9071f8b66/'
files=[glob.glob(U+'*Edition_1.pdf')[0]]+[glob.glob(U+f'*Edition-{n}.pdf')[0] for n in range(2,11)]
H=collections.Counter(); foot=[]
for fi,f in enumerate(files,1):
    for pi,ws in enumerate(pages(f),1):
        for c in page_text(ws):
            for y,h,t in c:
                H[round(h,1)]+=1
                if y>600: foot.append((fi,pi,t))
print(H.most_common(15))
import json;json.dump(foot,open('foot.json','w'))
print(len(foot)); print(foot[:5],foot[-5:])
