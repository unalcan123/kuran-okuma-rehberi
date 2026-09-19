const { launch, sleep, enableSemantics, labels, clickText } = require('./lib');
const url = process.argv[2];
const label = process.argv[3];

(async () => {
  const { browser, page, audioRequests } = await launch({ url });
  await sleep(5000);
  await enableSemantics(page);
  await clickText(page, 'Elifba Dersleri');
  await sleep(1200);
  await clickText(page, 'Harfleri Tanıyalım');
  await sleep(3000); // give preloading (new build) time to finish
  const ls = await labels(page);
  const cards = ls.filter((l) => /^[A-ZŞÇİ][a-zıışçğüö]+ [ء-ي]$/.test(l.label));
  const one = async (n) => {
    const reqBefore = audioRequests.length;
    const playingBefore = await page.evaluate(() => window.__playing.length);
    const t = await page.evaluate(() => performance.now());
    await page.mouse.click(n.x + n.w / 2, n.y + n.h / 2);
    let lat = null;
    for (let i = 0; i < 60; i++) {
      await sleep(50);
      const r = await page.evaluate((b) => (window.__playing.length > b ? window.__playing[b] : null), playingBefore);
      if (r) { lat = Math.round(r - t); break; }
    }
    return { letter: n.label.split(' ')[0], msToSound: lat, netRequests: audioRequests.length - reqBefore };
  };
  const singles = [];
  for (const n of cards.slice(0, 6)) { singles.push(await one(n)); await sleep(600); }
  // rapid taps: 8 different letters, 90 ms apart, then see what is playing
  const pb = await page.evaluate(() => window.__playing.length);
  const reqB = audioRequests.length;
  for (const n of cards.slice(0, 8)) { await page.mouse.click(n.x + n.w / 2, n.y + n.h / 2); await sleep(90); }
  await sleep(1500);
  const playingAfter = await page.evaluate(() => window.__playing.length);
  const plays = await page.evaluate(() => window.__plays.slice(-8).map((p) => p.kind));
  console.log(`\n=== ${label} ===`);
  console.log('one tap at a time (ms from tap until the sound actually starts):');
  singles.forEach((s) => console.log(`  ${s.letter.padEnd(5)} ${String(s.msToSound).padStart(5)} ms   network requests: ${s.netRequests}`));
  const ok = singles.filter((s) => s.msToSound != null).map((s) => s.msToSound);
  console.log(`  average: ${ok.length ? Math.round(ok.reduce((a, b) => a + b, 0) / ok.length) : 'n/a'} ms   (never started: ${singles.length - ok.length})`);
  console.log(`rapid 8 taps: sounds that started: ${playingAfter - pb}, network requests: ${audioRequests.length - reqB}, sources: ${[...new Set(plays)].join(',')}`);
  await browser.close();
})().catch((e) => { console.error('FAIL', e.message); process.exit(1); });
