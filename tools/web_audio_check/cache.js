const { launch, sleep, enableSemantics, clickText } = require('./lib');
async function cacheInfo(page) {
  return page.evaluate(async () => {
    const c = await caches.open('flutter-app-cache');
    const reqs = await c.keys();
    return { entries: reqs.length, audioInCache: reqs.filter((r) => r.url.includes('/audio/')).length, controlled: !!navigator.serviceWorker.controller };
  });
}
async function openLesson(page) {
  await enableSemantics(page);
  await clickText(page, 'Elifba Dersleri'); await sleep(1200);
  await clickText(page, 'Harfleri Tanıyalım'); await sleep(3500);
}
(async () => {
  const { browser, page, audioRequests } = await launch({ url: process.argv[2] || 'http://localhost:8099/' });
  await sleep(5000);
  console.log('before any lesson:', JSON.stringify(await cacheInfo(page)));
  await openLesson(page);
  console.log(`1st open of Ders 1 -> audio responses=${audioRequests.responses}, via service worker=${audioRequests.fromSW || 0}`, JSON.stringify(await cacheInfo(page)));
  audioRequests.responses = 0; audioRequests.fromSW = 0;
  await page.reload({ waitUntil: 'networkidle2' });
  await sleep(5000);
  await openLesson(page);
  console.log(`after page reload, 2nd open -> audio responses=${audioRequests.responses}, via service worker cache=${audioRequests.fromSW || 0}`, JSON.stringify(await cacheInfo(page)));
  await browser.close();
})().catch((e) => { console.error('FAIL', e.message); process.exit(1); });
