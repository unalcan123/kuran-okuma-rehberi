// Phone held sideways. Some browsers keep screen.width/height UNROTATED
// (393 x 852) while the page is laid out 852 x 393 css px.
//   node phone_landscape.js <url> <prefix> [unrotated|rotated]
const puppeteer = require('puppeteer-core');
const url = process.argv[2];
const prefix = process.argv[3];
const mode = process.argv[4] || 'unrotated';
const W = 852, H = 393;
(async () => {
  const browser = await puppeteer.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: 'new', args: ['--no-sandbox', '--mute-audio'] });
  const page = await browser.newPage();
  const client = await page.createCDPSession();
  const screenW = mode === 'unrotated' ? 393 : 852;
  const screenH = mode === 'unrotated' ? 852 : 393;
  await client.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 2, mobile: true, screenWidth: screenW, screenHeight: screenH });
  await page.goto(url, { waitUntil: 'networkidle2' });
  await new Promise((r) => setTimeout(r, 6000));
  console.log(prefix, mode, JSON.stringify(await page.evaluate(() => ({ innerWidth, innerHeight, screenWidth: screen.width, screenHeight: screen.height }))));
  const shot = async (name) => { const r = await client.send('Page.captureScreenshot', { format: 'png' }); require('fs').writeFileSync(name, Buffer.from(r.data, 'base64')); };
  await shot(`${prefix}_home.png`);
  await page.evaluate(() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); });
  await new Promise((r) => setTimeout(r, 700));
  const click = async (text) => {
    const nodes = await page.evaluate((t) => [...document.querySelectorAll('flt-semantics')].map((e) => { const r = e.getBoundingClientRect(); return { label: (e.getAttribute('aria-label') || e.textContent || '').trim().replace(/\s+/g, ' '), x: r.x, y: r.y, w: r.width, h: r.height }; }).filter((n) => n.label.includes(t) && n.w > 0), text);
    nodes.sort((a, b) => a.w * a.h - b.w * b.h);
    await page.mouse.click(nodes[0].x + nodes[0].w / 2, nodes[0].y + nodes[0].h / 2);
    await new Promise((r) => setTimeout(r, 1500));
  };
  await click('Elifba Dersleri');
  await shot(`${prefix}_dersler.png`);
  await browser.close();
})().catch((e) => { console.error('FAIL', e.message); process.exit(1); });
