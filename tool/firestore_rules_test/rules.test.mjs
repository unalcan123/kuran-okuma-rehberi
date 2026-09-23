// firestore.rules testleri — Firestore emülatöründe çalışır (Google hesabı gerekmez).
//   cd tool/firestore_rules_test && npm install && npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getCountFromServer,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-kuran-okuma',
    firestore: { rules: readFileSync('../../firestore.rules', 'utf8') },
  });
});
after(() => env?.cleanup());
beforeEach(() => env.clearFirestore());

const db = (uid) => env.authenticatedContext(uid).firestore();
const pid = (uid, profile = 'p1') => `${uid}_${profile}`;
const sid = (game, playerId) => `${game}__${playerId}`;

/** Geçerli bir skor belgesi (Bul & Patlat, 20 doğru, hepsi ilk denemede). */
function score(uid, overrides = {}, profile = 'p1') {
  return {
    playerId: pid(uid, profile),
    ownerUid: uid,
    nickname: 'Ahmed',
    gameId: 'bul_patlat',
    bestScore: 330, // 20 × 15 + 6 × 5
    correctAnswers: 20,
    wrongAnswers: 2,
    missedTargets: 1,
    totalItems: 40,
    accuracy: 87, // round(2000 / 23)
    bestAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

const scoreRef = (fs, uid, game = 'bul_patlat', profile = 'p1') =>
  doc(fs, 'leaderboard_scores', sid(game, pid(uid, profile)));

/** Uygulamadaki submitBest ile aynı: işlemde oku, yalnızca yüksekse yaz. */
async function submitBest(uid, nickname, game, bestScore, correct, profile = 'p1') {
  const fs = db(uid);
  const ref = scoreRef(fs, uid, game, profile);
  await runTransaction(fs, async (tx) => {
    const snap = await tx.get(ref);
    const old = snap.exists() ? snap.data().bestScore : null;
    if (old !== null && bestScore <= old) return;
    tx.set(
      ref,
      score(
        uid,
        {
          nickname,
          gameId: game,
          bestScore,
          correctAnswers: correct,
          wrongAnswers: 0,
          missedTargets: 0,
          totalItems: correct + 5,
          accuracy: correct === 0 ? 0 : 100,
        },
        profile,
      ),
    );
  });
}

/** Uygulamadaki top + countAhead + countPlayers ile aynı sorgular. */
async function board(viewerUid, game, myPlayerId) {
  const fs = db(viewerUid);
  const col = collection(fs, 'leaderboard_scores');
  const top = await getDocs(
    query(col, where('gameId', '==', game), orderBy('bestScore', 'desc'), orderBy('bestAt'), limit(10)),
  );
  const total = (await getCountFromServer(query(col, where('gameId', '==', game)))).data().count;
  let rank = null;
  if (myPlayerId) {
    const mine = (await getDoc(doc(fs, 'leaderboard_scores', sid(game, myPlayerId)))).data();
    const higher = (await getCountFromServer(
      query(col, where('gameId', '==', game), where('bestScore', '>', mine.bestScore)),
    )).data().count;
    const tied = (await getCountFromServer(
      query(col, where('gameId', '==', game), where('bestScore', '==', mine.bestScore), where('bestAt', '<', mine.bestAt)),
    )).data().count;
    rank = higher + tied + 1;
  }
  return { rows: top.docs.map((d) => `${d.data().nickname} ${d.data().bestScore}`), total, rank };
}

describe('leaderboard_scores okuma', () => {
  test('oturumsuz okunamaz, anonim oturumla okunur', async () => {
    await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'leaderboard_scores')));
    await assertSucceeds(getDocs(collection(db('alice'), 'leaderboard_scores')));
  });
});

describe('leaderboard_scores yazma', () => {
  test('kendi geçerli skorunu oluşturur', async () => {
    await assertSucceeds(setDoc(scoreRef(db('alice'), 'alice'), score('alice')));
  });

  test('başkasının adına yazamaz', async () => {
    const fs = db('mallory');
    await assertFails(setDoc(scoreRef(fs, 'alice'), score('alice')));
    await assertFails(setDoc(scoreRef(fs, 'alice'), score('alice', { ownerUid: 'mallory' })));
    await assertFails(setDoc(doc(fs, 'leaderboard_scores', sid('bul_patlat', pid('mallory'))), score('mallory', { playerId: pid('alice') })));
  });

  test('belge kimliği oyun/oyuncuyla uyuşmalı', async () => {
    const fs = db('alice');
    await assertFails(setDoc(doc(fs, 'leaderboard_scores', 'x'), score('alice')));
    await assertFails(setDoc(scoreRef(fs, 'alice', 'harf_arabalari'), score('alice')));
  });

  test('tutarsız/imkansız skorlar reddedilir', async () => {
    const fs = db('alice');
    const ref = scoreRef(fs, 'alice');
    const bad = {
      negatif: { bestScore: -5 },
      besin_kati_degil: { bestScore: 332 },
      cok_yuksek: { bestScore: 400 }, // 20 doğruyla en çok 330
      cok_dusuk: { bestScore: 195 }, // 20 doğru en az 200
      sinir_ustu: { bestScore: 4005, correctAnswers: 241, totalItems: 300, accuracy: 100, wrongAnswers: 0, missedTargets: 0 },
      dogru_ogeden_fazla: { totalItems: 19 },
      dogruluk_yanlis: { accuracy: 100 },
      dogruluk_aralik_disi: { accuracy: 101 },
      kacan_fazla: { missedTargets: 6, accuracy: 71 },
      ondalik: { bestScore: 330.5 },
      metin: { bestScore: '330' },
      bilinmeyen_oyun: { gameId: 'baska_oyun' },
      fazla_alan: { email: 'a@b.c' },
      istemci_zamani: { bestAt: new Date() },
      kotu_ad: { nickname: '<script>' },
    };
    for (const [name, o] of Object.entries(bad)) {
      await assertFails(setDoc(ref, score('alice', o)), name);
    }
  });

  test('Harf Arabaları: kaçan hedef 5\'ten fazla olabilir', async () => {
    const fs = db('alice');
    await assertSucceeds(
      setDoc(scoreRef(fs, 'alice', 'harf_arabalari'), score('alice', { gameId: 'harf_arabalari', missedTargets: 9, accuracy: 65 })),
    );
  });

  test('yalnızca daha yüksek skorla güncellenir', async () => {
    const fs = db('alice');
    const ref = scoreRef(fs, 'alice');
    await assertSucceeds(setDoc(ref, score('alice')));
    await assertFails(setDoc(ref, score('alice', { bestScore: 300 })));
    await assertFails(setDoc(ref, score('alice')));
    await assertSucceeds(setDoc(ref, score('alice', { bestScore: 335, correctAnswers: 21, totalItems: 40, accuracy: 88 })));
    await assertFails(updateDoc(ref, { bestScore: 5000 }));
  });

  test('başkasının skorunu değiştiremez / silemez', async () => {
    await assertSucceeds(setDoc(scoreRef(db('alice'), 'alice'), score('alice')));
    const fs = db('mallory');
    await assertFails(setDoc(scoreRef(fs, 'alice'), score('alice', { bestScore: 335, correctAnswers: 21, accuracy: 88 })));
    await assertFails(deleteDoc(scoreRef(fs, 'alice')));
  });

  test('kendi kaydını silebilir (yoksa da)', async () => {
    const fs = db('alice');
    await assertSucceeds(deleteDoc(scoreRef(fs, 'alice', 'harf_arabalari')));
    await assertSucceeds(setDoc(scoreRef(fs, 'alice'), score('alice')));
    await assertSucceeds(deleteDoc(scoreRef(fs, 'alice')));
  });
});

describe('players', () => {
  const player = (uid, nickname, profile = 'p1') => ({
    playerId: pid(uid, profile),
    ownerUid: uid,
    nickname,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });

  test('kendi profilini oluşturur, okur, günceller, siler', async () => {
    const fs = db('alice');
    const ref = doc(fs, 'players', pid('alice'));
    await assertSucceeds(getDoc(ref)); // henüz yok
    await assertSucceeds(setDoc(ref, player('alice', 'Ahmed')));
    await assertSucceeds(updateDoc(ref, { nickname: 'Ahmed Can', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { ownerUid: 'x', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { createdAt: serverTimestamp(), updatedAt: serverTimestamp() }));
    await assertSucceeds(deleteDoc(ref));
  });

  test('takma ad kuralları', async () => {
    const fs = db('alice');
    const ok = ['Ahmed', 'Şükrü Öz', 'أحمد', 'Elif_2', 'Ay', 'a'.repeat(16)];
    const bad = ['A', 'a'.repeat(17), ' Ahmed', 'Ahmed ', 'Ah  med', '<b>Ali</b>', 'Ali;', 'x"y', '', 'Ali\n', 42];
    let i = 0;
    for (const n of ok) {
      await assertSucceeds(setDoc(doc(fs, 'players', pid('alice', `ok${i++}`)), player('alice', n, `ok${i - 1}`)), n);
    }
    for (const n of bad) {
      await assertFails(setDoc(doc(fs, 'players', pid('alice', `bad${i++}`)), player('alice', n, `bad${i - 1}`)), String(n));
    }
  });

  test('başkasının profili okunamaz/yazılamaz, liste kapalı', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'players', pid('alice')), player('alice', 'Ahmed')));
    const fs = db('mallory');
    await assertFails(getDoc(doc(fs, 'players', pid('alice'))));
    await assertFails(setDoc(doc(fs, 'players', pid('alice', 'p2')), player('alice', 'X', 'p2')));
    await assertFails(getDocs(collection(fs, 'players')));
    await assertFails(setDoc(doc(fs, 'players', pid('mallory')), { ...player('mallory', 'M'), email: 'x' }));
  });

  test('diğer koleksiyonlar kapalı', async () => {
    await assertFails(setDoc(doc(db('alice'), 'anything', 'x'), { a: 1 }));
    await assertFails(getDoc(doc(db('alice'), 'anything', 'x')));
  });
});

describe('sıralama senaryosu (görevdeki örnek)', () => {
  for (const game of ['bul_patlat', 'harf_arabalari']) {
    test(`${game}: en iyi korunur, sıra ve toplam doğru`, async () => {
      // Ahmed 300 (20 doğru), Elif 450 (30), Yusuf 400 (27: 405 değil, 400 = 10·27+... geçerli)
      await submitBest('uidA', 'Ahmed', game, 300, 20);
      await submitBest('uidB', 'Elif', game, 450, 30);
      await submitBest('uidC', 'Yusuf', game, 400, 27);
      let b = await board('uidA', game, pid('uidA'));
      assert(b.rows, ['Elif 450', 'Yusuf 400', 'Ahmed 300']);
      assert([b.rank, b.total], [3, 3]);

      await submitBest('uidA', 'Ahmed', game, 500, 34);
      b = await board('uidA', game, pid('uidA'));
      assert(b.rows, ['Ahmed 500', 'Elif 450', 'Yusuf 400']);
      assert([b.rank, b.total], [1, 3]);

      await submitBest('uidA', 'Ahmed', game, 200, 15); // düşük: yazılmaz
      b = await board('uidA', game, pid('uidA'));
      assert(b.rows, ['Ahmed 500', 'Elif 450', 'Yusuf 400']);

      // Aynı takma adla iki farklı oyuncu (farklı UID) ayrı satırdır.
      await submitBest('uidD', 'Ahmed', game, 250, 17);
      b = await board('uidD', game, pid('uidD'));
      assert(b.rows, ['Ahmed 500', 'Elif 450', 'Yusuf 400', 'Ahmed 250']);
      assert([b.rank, b.total], [4, 4]);
    });
  }

  test('ilk 10 dışındaki oyuncunun sırası ve eşit puanda önce ulaşan önde', async () => {
    const game = 'bul_patlat';
    for (let i = 0; i < 12; i++) {
      await submitBest(`u${i}`, `Oyuncu ${i}`, game, 600 - i * 20, 36);
    }
    // 12 oyuncu: 600 … 380. Sonra iki kişi 380'e ulaşır (u11 önce ulaştı).
    await submitBest('late', 'Geç Gelen', game, 380, 25);
    const b = await board('late', game, pid('late'));
    assert(b.rows.length, 10);
    assert([b.rank, b.total], [13, 13]);
    const early = await board('u11', game, pid('u11'));
    assert(early.rank, 12);
  });
});

function assert(actual, expected) {
  const a = JSON.stringify(actual), e = JSON.stringify(expected);
  if (a !== e) throw new Error(`beklenen ${e}, gelen ${a}`);
}
