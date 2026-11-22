const L = require('./lib.js');
const fs = require('fs');
const W = 390, H = 844;
const frac = (r) => [r.x / W, r.y / H, r.w / W, r.h / H].map(v => Math.round(v * 10000) / 10000);
const union = (rs) => { const x = Math.min(...rs.map(r => r.x)), y = Math.min(...rs.map(r => r.y)), x2 = Math.max(...rs.map(r => r.x + r.w)), y2 = Math.max(...rs.map(r => r.y + r.h)); return { x, y, w: x2 - x, h: y2 - y }; };
const T = {
  fr: { plus: /^Plus$/, bible: /^Bible$/, settings: /^Réglages/, journal: /^Journal de prière/, backup: /^Sauvegarde de mes données/, lang: [/^Français$/, /^Kiswahili$/], size: /^Taille du texte/, newEntry: /^Nouvelle entrée/, exp: /^Exporter mes données/, imp: /^Importer une sauvegarde/ },
  sw: { plus: /^Zaidi$/, bible: /^Biblia$/, settings: /^Mipangilio/, journal: /^Shajara ya maombi/, backup: /^Hifadhi ya data yangu/, lang: [/^Français$/, /^Kiswahili$/], size: /^Ukubwa wa maandishi/, newEntry: /^Maingizo mapya/, exp: /^Hamisha data yangu/, imp: /^Leta hifadhi/ },
};
const jobs = {
  settings_lang: async (p, t) => {
    await L.tap(p, t.plus); await L.tapScroll(p, t.settings);
    const a = await L.find(p, t.lang[0]), b = await L.find(p, t.lang[1]), s = await L.find(p, t.size);
    return { lang: union([a, b]), size: { x: s.x, y: s.y, w: s.w, h: 125 } };
  },
  journal: async (p, t) => { await L.tap(p, t.plus); await L.tapScroll(p, t.journal); return { new: await L.find(p, t.newEntry) }; },
  backup: async (p, t) => { await L.tap(p, t.plus); await L.tapScroll(p, t.backup); return { export: await L.find(p, t.exp), import: await L.find(p, t.imp) }; },
  bible_versions: async (p, t) => { await L.tap(p, t.bible); await L.tap(p, /^La Bible annotée$/); return { version: await L.find(p, /^Louis Segond 1910\s+La Bible annotée/) }; },
  chapter_intro: async (p, t) => { await L.tap(p, t.bible); await L.tap(p, /^La Bible annotée$/); await L.tap(p, /^Genèse/, 3500); return { intro: await L.find(p, /^Introduction/) }; },
  bible_modes: async (p, t) => { await L.tap(p, t.bible); await L.tap(p, /^La Bible annotée$/); await L.tap(p, /^Genèse/); await L.tap(p, /^Chapitre 1$|^Chapter 1$/, 2500); await L.tap(p, /^Étude$/, 2000);
    return { modes: union([await L.find(p, /^Texte$/), await L.find(p, /^Étude$/), await L.find(p, /^Notes$/)]) }; },
};
const only = { fr: Object.keys(jobs), sw: ['settings_lang', 'journal', 'backup'] };
(async () => {
  const manifest = JSON.parse(fs.existsSync(__dirname + '/out/manifest.json') ? fs.readFileSync(__dirname + '/out/manifest.json') : '{}');
  const want = process.argv.slice(2);
  for (const lang of ['fr', 'sw']) {
    manifest[lang] = manifest[lang] || {};
    for (const id of only[lang]) {
      if (want.length && !want.includes(id) && !want.includes(lang + ':' + id)) continue;
      const { b, p } = await L.start(lang);
      try {
        const rects = await jobs[id](p, T[lang]);
        await p.waitForTimeout(800);
        const png = `${__dirname}/out/${lang}_${id}.png`;
        await p.screenshot({ path: png });
        const out = {};
        for (const [k, r] of Object.entries(rects)) { if (!r) throw new Error('zone absente ' + k); out[k] = frac(r); }
        manifest[lang][id] = { w: W * 2, h: H * 2, rects: out };
        console.log('OK', lang, id, JSON.stringify(out));
      } catch (e) { console.log('ECHEC', lang, id, e.message.slice(0, 300)); }
      await b.close();
    }
  }
  fs.writeFileSync(__dirname + '/out/manifest.json', JSON.stringify(manifest, null, 1));
})();
