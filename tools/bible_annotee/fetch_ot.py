import os, sys, time, urllib.request, urllib.error
OUT = sys.argv[1]
abr = "gen exo lev nom deu josue juges ruth 1samuel 2samuel 1rois 2rois 1chroniques 2chroniques esdras nehemie esther job proverbes ecclesiaste cantique psaumes esaie jeremie lamentations ezechiel daniel osee joel amos abdias jonas michee nahum habakuk sophonie aggee zacharie malachie".split()
chap = [50,40,27,36,34,24,21,4,31,24,22,25,29,36,10,13,10,42,31,12,8,150,66,52,5,48,12,14,3,9,1,4,7,3,3,3,2,14,4]
os.makedirs(OUT, exist_ok=True)
ua = "Mozilla/5.0 (compatible; EMUCompagnon-research; lecture lente, 1 page par seconde)"
done = fail = 0
for a, n in zip(abr, chap):
    for c in range(1, n + 1):
        path = f"{OUT}/{a}{c}_t.html"
        if os.path.exists(path) and os.path.getsize(path) > 200:
            continue
        url = f"https://theotex.org/ba/ba_{a}/{a}{c}_t.html"
        for attempt in range(3):
            try:
                req = urllib.request.Request(url, headers={"User-Agent": ua})
                data = urllib.request.urlopen(req, timeout=30).read()
                open(path, "wb").write(data)
                done += 1
                break
            except Exception as e:
                time.sleep(5 * (attempt + 1))
        else:
            fail += 1
            print("ECHEC", url, flush=True)
        time.sleep(1.2)
    print("livre", a, "ok", flush=True)
print("FIN", done, "récupérés,", fail, "échecs", flush=True)
