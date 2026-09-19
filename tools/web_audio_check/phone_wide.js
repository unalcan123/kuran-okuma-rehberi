// Reproduces the user's phone: the browser lays the page out ~880 css px wide
// while the device screen is 393 css px (desktop-site mode / ignored viewport).
const puppeteer = require('puppeteer-core');
const url = process.argv[2];
const prefix = process.argv[3];
const LAYOUT = Number(process.argv[4] || 880);
(async () => {
  const browser = await puppeteer.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: 'new', args: ['--no-sandbox', '--mute-audio'] });
  const page = await browser.newPage();
  const client = await page.createCDPSession();
  const H = Math.round(LAYOUT * 852 / 393);
  await client.send('Emulation.setDeviceMetricsOverride', { width: LAYOUT, height: H, deviceScaleFactor: 1, mobile: false, screenWidth: 393, screenHeight: 852 });
  await page.goto(url, { waitUntil: 'networkidle2' });
  await new Promise((r) => setTimeout(r, 6000));
  const info = await page.evaluate(() => ({ innerWidth: innerWidth, screenWidth: screen.width, innerHeight: innerHeight }));
  console.log(prefix, JSON.stringify(info));
  const shot = async (name) => { const r = await client.send('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: LAYOUT, height: H, scale: 393 / LAYOUT * 2 } }); require('fs').writeFileSync(name, Buffer.from(r.data, 'base64')); };
  await shot(`${prefix}_home.png`);
  // open Elifba -> Ders 1
  await page.evaluate(() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); });
  await new Promise((r) => setTimeout(r, 700));
  const click = async (text) => {
    const nodes = await page.evaluate((t) => [...document.querySelectorAll('flt-semantics')].map((e) => { const r = e.getBoundingClientRect(); return { label: (e.getAttribute('aria-label') || e.textContent || '').trim().replace(/\s+/g, ' '), x: r.x, y: r.y, w: r.width, h: r.height }; }).filter((n) => n.label.includes(t) && n.w > 0), text);
    nodes.sort((a, b) => a.w * a.h - b.w * b.h);
    await page.mouse.click(nodes[0].x + nodes[0].w / 2, nodes[0].y + nodes[0].h / 2);
    await new Promise((r) => setTimeout(r, 1500));
  };
  await click('Elifba Dersleri');
  await click('Harfleri Tanıyalım');
  await shot(`${prefix}_ders1.png`);
  await browser.close();
})().catch((e) => { console.error('FAIL', e.message); process.exit(1); });
