import re,json,html
x=open('/tmp/claude-0/dx/word/document.xml',encoding='utf8').read()
body=x.split('<w:body>')[1]
ps=re.findall(r'<w:p[ >].*?</w:p>',body,flags=re.S)
paras=[]
for p in ps:
    runs=re.findall(r'<w:r[ >].*?</w:r>',p,flags=re.S)
    txt='';bold=False;ital=False
    for r in runs:
        t=''.join(re.findall(r'<w:t[^>]*>([^<]*)</w:t>',r))
        if '<w:tab/>' in r: t='\t'+t
        if not t.strip(): txt+=t; continue
        b='<w:b/>' in r or '<w:b ' in r; i='<w:i/>' in r
        if b and not ('<w:b w:val="0"' in r): bold=bold or b
        ital=ital or i
        txt+=t
    paras.append((html.unescape(txt).replace(' ',' ').strip(),bold,ital))
json.dump(paras,open('paras.json','w'),ensure_ascii=False)
print(len(paras))
# start of hymns: first para matching heading after index
start=[i for i,(t,b,it) in enumerate(paras) if re.match(r'^1 \S',t) and b and it]
print(start[:5])
for i in start[:1]: print(paras[i-3:i+12])
