const puppeteer = require('puppeteer-core');

const CHROME = process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe';

async function launch({ width = 800, height = 1100, url = 'http://localhost:8099/', userDataDir } = {}) {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    userDataDir,
    args: ['--autoplay-policy=no-user-gesture-required', '--no-sandbox', '--mute-audio'],
  });
  const page = await browser.newPage();
  await page.setViewport({ width, height });
  const audioRequests = [];
  page.on('response', (res) => {
    if (res.url().includes('/audio/')) audioRequests.fromSW = (audioRequests.fromSW || 0) + (res.fromServiceWorker() ? 1 : 0), audioRequests.fromDisk = (audioRequests.fromDisk || 0) + (res.fromCache() ? 1 : 0), audioRequests.responses = (audioRequests.responses || 0) + 1;
  });
  page.on('request', (r) => {
    if (r.url().includes('/audio/')) audioRequests.push({ t: Date.now(), url: r.url().split('/assets/assets/')[1] });
  });
  page.on('pageerror', (e) => console.log('PAGE ERROR', e.message));
  page.on('console', (m) => { const t = m.text(); if (/audio|error/i.test(t)) console.log('console:', t.slice(0, 200)); });
  await page.evaluateOnNewDocument(() => {
    window.__plays = [];
    window.__playing = [];
    const orig = HTMLMediaElement.prototype.play;
    HTMLMediaElement.prototype.play = function () {
      this.addEventListener('playing', () => window.__playing.push(performance.now()), { once: true });
      window.__plays.push({ t: performance.now(), src: (this.src || '').slice(0, 60), kind: (this.src || '').startsWith('data:') ? 'memory(data-uri)' : 'network-url' });
      return orig.apply(this, arguments);
    };
  });
  await page.goto(url, { waitUntil: 'networkidle2' });
  return { browser, page, audioRequests };
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function enableSemantics(page) {
  await page.evaluate(() => {
    const p = document.querySelector('flt-semantics-placeholder');
    if (p) p.click();
  });
  await sleep(600);
}

async function labels(page) {
  return page.evaluate(() =>
    [...document.querySelectorAll('flt-semantics')]
      .map((e) => {
        const r = e.getBoundingClientRect();
        return { label: (e.getAttribute('aria-label') || e.textContent || '').trim().replace(/\s+/g, ' ').slice(0, 60), role: e.getAttribute('role'), x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width), h: Math.round(r.height) };
      })
      .filter((e) => e.label && e.w > 0 && e.h > 0),
  );
}

async function clickText(page, text, { exact = false, nth = 0 } = {}) {
  const found = (await labels(page))
    .filter((l) => (exact ? l.label === text : l.label.includes(text)))
    .sort((a, b) => a.w * a.h - b.w * b.h); // smallest = the leaf, not a container
  if (!found[nth]) throw new Error(`no semantic node "${text}" among: ` + (await labels(page)).map((l) => l.label).slice(0, 30).join(' | '));
  const l = found[nth];
  await page.mouse.click(l.x + l.w / 2, l.y + l.h / 2);
  return l;
}

module.exports = { launch, sleep, enableSemantics, labels, clickText };
