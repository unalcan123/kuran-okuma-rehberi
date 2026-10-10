const { launch, sleep, enableSemantics, clickText } = require('./lib');
const URL_ = process.argv[2];
async function stores(page) {
  return page.evaluate(async () => {
    const out = {};
    for (const k of await caches.keys()) out[k] = (await (await caches.open(k)).keys()).filter((r) => r.url.includes('kuran-sounds/') ).length;
    return out;
  });
}
async function openLesson(page) {
  await enableSemantics(page);
  await clickText(page, "Kur'an Okuma Rehberi", { exact: true, nth: 1 }); await sleep(1200);
  await clickText(page, 'Ders 1 · Harfleri Tanıyalım', { exact: true }); await sleep(3500);
}
(async () => {
  const { browser, page, audioRequests } = await launch({ url: URL_ });
  await sleep(5000);
  let mark = audioRequests.length;
  await openLesson(page);
  console.log(`1st visit  -> audio downloads from the server: ${audioRequests.length - mark}; stored on device:`, JSON.stringify(await stores(page)));
  await page.reload({ waitUntil: 'networkidle2' });
  await sleep(5000);
  mark = audioRequests.length;
  await openLesson(page);
  console.log(`after reload (2nd visit) -> audio downloads from the server: ${audioRequests.length - mark}`);
  // tap a letter: still from memory, no download?
  const mark2 = audioRequests.length;
  await clickText(page, 'Elif. Dinle'); await sleep(500);
  console.log('a tap downloads:', audioRequests.length - mark2, '| audio downloads so far in 2nd visit:', audioRequests.length - mark);
  await browser.close();
})().catch((e) => { console.error('FAIL', e.message); process.exit(1); });
