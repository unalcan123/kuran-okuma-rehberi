// The web sound engine in real Chrome (docs/SES.md, "Web ses motoru"):
// letters from decoded buffers, no element→Web Audio bridge, one audio
// context made on the first real touch, nodes and object URLs let go, quick
// taps, a surah's "Dinle" at speed 0.75 (set before play, pitch kept, next
// ayet by itself), and letters back at 1.0 afterwards.
// Chrome passing does NOT prove that iPhone / iPad Safari is fine.
//   node engine.js http://localhost:8099/
const { launch, sleep, enableSemantics, labels } = require('./lib');
const url = (process.argv[2] || 'http://localhost:8099/').replace(/\/?$/, '/') + '?sesTani=1';

function hooks() {
  // Saved reading speed 0.75 (shared_preferences on the web).
  localStorage.setItem('flutter.reading.speed', '0.75');
  const s = (window.__snd = { contexts: 0, bridges: 0, decodes: 0, starts: [], ended: 0, plays: [], urlsMade: 0, urlsRevoked: 0 });
  const AC = window.AudioContext;
  window.AudioContext = class extends AC { constructor(...a) { super(...a); s.contexts++; } };
  const bridge = AC.prototype.createMediaElementSource;
  AC.prototype.createMediaElementSource = function (...a) { s.bridges++; return bridge.apply(this, a); };
  const decode = BaseAudioContext.prototype.decodeAudioData;
  BaseAudioContext.prototype.decodeAudioData = function (...a) { s.decodes++; return decode.apply(this, a); };
  const start = AudioBufferSourceNode.prototype.start;
  AudioBufferSourceNode.prototype.start = function (...a) {
    if (this.buffer && this.buffer.length > 1) {
      s.starts.push({ t: performance.now(), dur: this.buffer.duration, rate: this.playbackRate.value });
      this.addEventListener('ended', () => s.ended++);
    }
    return start.apply(this, a);
  };
  const play = HTMLMediaElement.prototype.play;
  HTMLMediaElement.prototype.play = function (...a) {
    s.plays.push({ t: performance.now(), src: (this.src || '').slice(0, 5), rate: this.playbackRate, def: this.defaultPlaybackRate, pitch: this.preservesPitch });
    return play.apply(this, a);
  };
  const make = URL.createObjectURL, revoke = URL.revokeObjectURL;
  URL.createObjectURL = function (b) { s.urlsMade++; return make.call(URL, b); };
  URL.revokeObjectURL = function (u) { s.urlsRevoked++; return revoke.call(URL, u); };
}

const snd = (page) => page.evaluate(() => JSON.parse(JSON.stringify(window.__snd)));
const tap = (page, l) => page.mouse.click(l.x + l.w / 2, l.y + l.h / 2);
async function find(page, test) {
  const found = (await labels(page)).filter(test).sort((a, b) => a.w * a.h - b.w * b.h);
  if (!found.length) throw new Error('bulunamadı: ' + test + ' — ' + (await labels(page)).map((l) => l.label).slice(0, 15).join(' | '));
  return found[0];
}

(async () => {
  const results = [];
  const check = (name, ok, detail) => { results.push(ok); console.log(`${ok ? 'GEÇTİ' : 'KALDI'}  ${name}${detail ? ' — ' + detail : ''}`); };
  const { browser, page } = await launch({ url, autoplay: false, beforeLoad: hooks });
  await sleep(6000);
  await enableSemantics(page); // a script's click: must not count as a touch
  let s = await snd(page);
  check('dokunuştan önce ses bağlamı kurulmaz', s.contexts === 0, `bağlam: ${s.contexts}`);

  // --- Elifba Ders 1 -----------------------------------------------------
  await tap(page, await find(page, (l) => l.label === "Kur'an Okuma Rehberi" && l.role === 'button'));
  await sleep(2000);
  s = await snd(page);
  check('ilk gerçek dokunuşta tek bağlam kurulur', s.contexts === 1, `bağlam: ${s.contexts}`);
  await tap(page, await find(page, (l) => l.label === 'Ders 1 · Harfleri Tanıyalım'));
  await sleep(4000);
  s = await snd(page);
  check('ders açılınca harfler arka planda çözülür', s.decodes >= 20, `çözülen: ${s.decodes}`);
  const cards = (await labels(page)).filter((l) => /^[A-ZŞÇİ][a-zıışçğüö]+\. Dinle /.test(l.label));
  if (cards.length < 8) throw new Error('harf kartı bulunamadı: ' + cards.length);

  const lat = [];
  for (const c of cards.slice(0, 6)) {
    const before = (await snd(page)).starts.length;
    const t = await page.evaluate(() => performance.now());
    await tap(page, c);
    let ms = null;
    for (let i = 0; i < 40 && ms == null; i++) {
      await sleep(25);
      const now = await snd(page);
      if (now.starts.length > before) ms = Math.round(now.starts[before].t - t);
    }
    lat.push(ms);
    await sleep(900);
  }
  const ok = lat.filter((x) => x != null);
  check('tek dokunuşlar çözülmüş buffer\'dan başlar', ok.length === 6, `dokunuştan sese ms: ${lat.join(', ')} (ort. ${Math.round(ok.reduce((a, b) => a + b, 0) / Math.max(ok.length, 1))})`);

  let before = (await snd(page)).starts.length;
  for (const c of cards.slice(0, 8)) { await tap(page, c); await sleep(90); }
  await sleep(2500);
  s = await snd(page);
  check('hızlı 8 dokunuş: her biri kendi sesini başlatır, eskisi durur', s.starts.length - before === 8, `başlayan: ${s.starts.length - before}`);
  check('bütün buffer kaynakları bitti / bırakıldı (düğüm birikmez)', s.starts.length === s.ended, `başlayan ${s.starts.length}, biten ${s.ended}`);
  check('harflerde öğe → Web Audio köprüsü yok, öğe de yok', s.bridges === 0 && s.plays.length === 0, `köprü ${s.bridges}, öğe play ${s.plays.length}`);

  // --- Sure: Dinle (kayıtlı hız 0,75) ------------------------------------
  await page.goBack(); await sleep(1200); await page.goBack(); await sleep(1500);
  await tap(page, await find(page, (l) => l.label === 'Namaz Sureleri' && l.role === 'button'));
  await sleep(2000);
  await tap(page, await find(page, (l) => l.role === 'button' && /Fatiha/.test(l.label)));
  await sleep(3000);
  const playsBefore = (await snd(page)).plays.length;
  await tap(page, await find(page, (l) => l.label === 'Dinle' && l.role === 'button'));
  await sleep(2000);
  s = await snd(page);
  const first = s.plays[playsBefore];
  check('sure Dinle: köprüsüz öğeden, bellekten (blob)', !!first && first.src === 'blob:' && s.bridges === 0, JSON.stringify(first || null));
  check('hız 0,75 çalmadan önce verilmiş (varsayılan da), perde korunuyor', !!first && first.rate === 0.75 && first.def === 0.75 && first.pitch === true, first && `hız ${first.rate}, varsayılan ${first.def}, perde ${first.pitch}`);
  // Besmele ~5 sn (0,75 hızda daha uzun) + 0,7 sn ara: sıradaki ayet kendiliğinden.
  for (let i = 0; i < 30 && (await snd(page)).plays.length - playsBefore < 2; i++) await sleep(500);
  s = await snd(page);
  const second = s.plays[playsBefore + 1];
  check('sıradaki ayet dokunuşsuz başlar, yine 0,75', !!second && second.rate === 0.75 && second.def === 0.75, second && `hız ${second.rate}`);

  await page.goBack(); await sleep(1500);
  s = await snd(page);
  check('çıkınca object URL\'ler bırakılır', s.urlsMade > 0 && s.urlsMade === s.urlsRevoked, `üretilen ${s.urlsMade}, bırakılan ${s.urlsRevoked}`);

  // --- Geri Elifba: hız 1,0'a döndü mü ------------------------------------
  await page.goBack(); await sleep(1500);
  await tap(page, await find(page, (l) => l.label === "Kur'an Okuma Rehberi" && l.role === 'button'));
  await sleep(1500);
  await tap(page, await find(page, (l) => l.label === 'Ders 1 · Harfleri Tanıyalım'));
  await sleep(2500);
  const elif = (await labels(page)).filter((l) => /^Elif\. Dinle /.test(l.label))[0];
  before = (await snd(page));
  await tap(page, elif); await sleep(800);
  s = await snd(page);
  const last = s.starts[before.starts.length];
  check('sureden sonra harf yine 1,0 hızda buffer\'dan', !!last && last.rate === 1 && s.plays.length === before.plays.length, last && `buffer hızı ${last.rate}`);
  check('bütün oturumda tek ses bağlamı', s.contexts === 1, `bağlam ${s.contexts}`);

  const diag = await page.evaluate(() => (window.__kuranAudioReport ? window.__kuranAudioReport() : ''));
  check('tanı günlüğü (?sesTani=1) derleme etiketini gösterir', /derleme: ses-deneme/.test(diag), diag.split('\n')[0]);
  console.log('\n--- tanı günlüğünden ---\n' + diag.split('\n').filter((l) => /element|bağlam|TAKILMA/.test(l)).slice(-12).join('\n'));
  await browser.close();
  const failed = results.filter((x) => !x).length;
  console.log(`\n${results.length - failed}/${results.length} denetim geçti`);
  process.exit(failed ? 1 : 0);
})().catch((e) => { console.error('FAIL', e.message); process.exit(1); });
