import os, re, sys, time, urllib.request
OUT = sys.argv[1]
books = "Matthieu Marc Luc Jean Actes Romains 1Corinthiens 2Corinthiens Galates Ephesiens Philippiens Colossiens 1Thessaloniciens 2Thessaloniciens 1Timothee 2Timothee Tite Philemon Hebreux Jacques 1Pierre 2Pierre 1Jean 2Jean 3Jean Jude Apocalypse".split()
ua = "Mozilla/5.0 (compatible; EMUCompagnon-research; lecture lente, 1 page par seconde)"
os.makedirs(OUT, exist_ok=True)
def get(url):
    for attempt in range(3):
        try:
            return urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": ua}), timeout=30).read()
        except Exception:
            time.sleep(5 * (attempt + 1))
    return None
for b in books:
    n = 1
    while True:
        name = f"{b}_nta_{n}.html"
        path = f"{OUT}/{name}"
        if os.path.exists(path) and os.path.getsize(path) > 200:
            data = open(path, 'rb').read()
        else:
            data = get(f"https://theotex.org/nta/{b}/{name}")
            time.sleep(1.2)
            if data is None:
                print("ECHEC", b, n, flush=True); break
            open(path, 'wb').write(data)
        nxt = f"{b}_nta_{n+1}.html"
        if nxt.encode() in data:
            n += 1
        else:
            break
    print("livre", b, n, "pages", flush=True)
print("FIN", flush=True)
