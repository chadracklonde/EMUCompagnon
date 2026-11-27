const { chromium } = require('playwright');
exports.open = async (lang) => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, locale: lang === 'sw' ? 'sw-TZ' : 'fr-FR' });
  const p = await ctx.newPage();
  await p.goto('http://localhost:8099/', { waitUntil: 'load' });
  await p.waitForTimeout(7000);
  const ph = await p.$('flt-semantics-placeholder');
  if (ph) { await ph.evaluate(e => e.click()); await p.waitForTimeout(1200); }
  return { b, p };
};
exports.nodes = (p) => p.evaluate(() => [...document.querySelectorAll('flt-semantics')].map(e => {
  const r = e.getBoundingClientRect();
  return { t: (e.getAttribute('aria-label') || e.innerText || '').trim(), x: r.x, y: r.y, w: r.width, h: r.height, role: e.getAttribute('role') };
}).filter(n => n.t && n.w > 0 && n.h > 0));
exports.find = async (p, re) => {
  const ns = await exports.nodes(p);
  const m = ns.filter(n => re.test(n.t));
  m.sort((a, b) => a.w * a.h - b.w * b.h);
  return m.length ? m[0] : null;
};
exports.tap = async (p, re, wait = 1200) => {
  const n = await exports.find(p, re);
  if (!n) throw new Error('introuvable: ' + re + ' parmi ' + (await exports.nodes(p)).map(x => x.t).join(' | ').slice(0, 600));
  await p.mouse.click(n.x + n.w / 2, n.y + n.h / 2);
  await p.waitForTimeout(wait);
};
exports.dump = async (p) => (await exports.nodes(p)).map(n => `${n.t.replace(/\n/g,' ').slice(0,60)} [${Math.round(n.x)},${Math.round(n.y)},${Math.round(n.w)}x${Math.round(n.h)}]`).join('\n');
exports.start = async (lang) => {
  const o = await exports.open(lang);
  await exports.tap(o.p, lang === 'sw' ? /^Kiswahili/ : /^Français/);
  await exports.tap(o.p, /^Continuer|^Endelea/, 2500);
  await exports.tap(o.p, /^Passer|^Ruka/, 2500);
  return o;
};
exports.step = async (p, re, name, wait) => { await exports.tap(p, re, wait || 1500); if (name) await p.screenshot({ path: __dirname + '/' + name + '.png' }); };
exports.scrollTo = async (p, re, max = 10) => {
  for (let i = 0; i < max; i++) {
    const n = await exports.find(p, re);
    if (n && n.y > 60 && n.y + n.h < 780) return n;
    await p.mouse.move(195, 420); await p.mouse.wheel(0, 260); await p.waitForTimeout(500);
  }
  return exports.find(p, re);
};
exports.tapScroll = async (p, re, wait = 1500) => { await exports.scrollTo(p, re); await exports.tap(p, re, wait); };
