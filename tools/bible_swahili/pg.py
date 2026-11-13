import re,subprocess,sys
def pages(pdf):
    out=subprocess.run(['pdftotext','-bbox',pdf,'-'],capture_output=True,text=True).stdout
    for pg in re.split(r'<page ',out)[1:]:
        ws=[(float(a),float(b),float(c),float(d),w) for a,b,c,d,w in re.findall(r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)</word>',pg)]
        yield ws
def page_text(ws,mid=216):
    res=[]
    for lo,hi in ((0,mid),(mid,999)):
        col=[w for w in ws if lo<=w[0]<hi]
        col.sort(key=lambda w:(round(w[1]),w[0]))
        lines=[];cur=[];y=None
        for w in col:
            if y is None or abs(w[1]-y)>3:
                if cur: lines.append(cur)
                cur=[w];y=w[1]
            else: cur.append(w)
        if cur: lines.append(cur)
        res.append([(l[0][1],l[0][3]-l[0][1],' '.join(x[4] for x in sorted(l,key=lambda x:x[0]))) for l in lines])
    return res
if __name__=='__main__':
    import glob
    f=glob.glob(sys.argv[1])[0]
    for i,ws in enumerate(pages(f)):
        if i+1 in map(int,sys.argv[2:]):
            for c in page_text(ws):
                print('=== col')
                for y,h,t in c: print(round(y),round(h,1),t)
