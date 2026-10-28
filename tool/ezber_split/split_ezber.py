"""Üç tekrarlı ezber kayıtlarını zil seslerinden ayetlere ayırır.

    python tool/ezber_split/split_ezber.py "H:/Music/sureler/tekrarli/asr.mp3" --surah 103
    python tool/ezber_split/split_ezber.py --batch   # SURAHS'taki bütün dosyalar

Kayıtlarda okumaların arasına aynı zil örneği ("tin", ~789 Hz, ~0,92 sn)
eklenmiş; zilin çevresi dijital sessizlik. Yöntem:

1. Kayıt mono 22,05 kHz'e çözülür (yalnız okunur; orijinale dokunulmaz).
2. Zil: ~789 Hz bandının enerji oranı yüksek kareler; her aday zil
   şablonuyla (ilk bulunan zil) korelasyonla doğrulanır.
3. Konuşma: DC'si alınmış sinyalin 20 ms RMS'i, gürültü tabanından
   SPEECH_DB yukarısı. Kesim noktası zilin çevresindeki sessizliğin içinde,
   konuşmanın bittiği/başladığı yerden PAD_S kadar dışarıda; konuşmanın
   içine asla düşmez.
4. Tekrar denetimi: parçaların log-mel özellikleri DTW ile karşılaştırılır;
   ardışık benzer parçalar bir grup (aynı ayet) sayılır. Ayet numarası zil
   sayısından değil, (varsa) Kur'an tilavetiyle eğitilmiş tanıma modelinin
   yazdığı metnin doğrulanmış metne benzerliğinden ve grup yapısından gelir.
5. Şüpheli durumlar (kelime kesilmiş olabilir, parçada zil kalıntısı, grup
   3 değil, tanıma ile grup uyuşmuyor, çok kısa parça) raporlanır.

Çıktı: tmp/ezber_split/<ad>/ altında her parça (tekrar) ayrı MP3,
her ayet için seçilen tekrar `NN_ayet.mp3` (besmele `00_besmele.mp3`),
`rapor.json` ve `rapor.md`. Uygulamaya otomatik eklenmez: insan dinleyip
onaylayınca kopyalanır.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import unicodedata
from dataclasses import dataclass, field, asdict
from difflib import SequenceMatcher
from pathlib import Path

import numpy as np
from scipy import signal

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tmp" / "ezber_split"
SOURCE_DIR = Path("H:/Music/sureler/tekrarli")
DIYANET = ROOT / "tool" / "sources" / "diyanet_arabic_extract.json"

SR = 22050
HOP = 0.01  # analysis frame step (s)
BELL_HZ = 788.7
BELL_BAND = (765.0, 815.0)
BELL_RATIO = 0.5  # share of the frame's energy in the bell band
BELL_MIN_S = 0.5
BELL_CORR = 0.9  # template correlation to accept a bell
SPEECH_DB = 14.0  # above the noise floor = speech
PAD_S = 0.25  # silence kept around speech
MIN_SEG_S = 0.8
EDGE_DB = 12.0  # speech this close to its peak at a cut edge = suspicious
GROUP_DTW = 0.55  # relative DTW distance below which two parts are repeats
PEEL_PAUSE_S = 0.5  # pause that may separate besmele from verse 1
GAIN_DB = -3  # the recordings are ~3 dB louder than the app's surah clips

# File → (surah no., app id). Surahs 12+ of the app (1-11 already have
# per-verse audio). Âyetel Kürsî and Nebe have no repeat recording.
SURAHS = {
    "duha.mp3": (93, "duha"),
    "insirah.mp3": (94, "insirah"),
    "tin.mp3": (95, "tin"),
    "gadir.mp3": (97, "kadir"),
    "zilzal.mp3": (99, "zilzal"),
    "22.Adiyat Suresi.mp3": (100, "adiyat"),
    "garia.mp3": (101, "karia"),
    "tekasur.mp3": (102, "tekasur"),
    "asr.mp3": (103, "asr"),
    "humeze.mp3": (104, "humeze"),
}

ISTIAZE = "اعوذ بالله من الشيطان الرجيم"
BESMELE = "بسم الله الرحمن الرحيم"


def ffmpeg() -> str:
    path = ROOT / "tmp" / "ffmpeg-path.txt"
    return path.read_text().strip() if path.exists() else "ffmpeg"


def decode(path: Path) -> np.ndarray:
    raw = subprocess.run(
        [ffmpeg(), "-v", "error", "-i", str(path), "-af",
         "pan=mono|c0=0.5*c0+0.5*c1", "-ar", str(SR), "-f", "f32le", "-"],
        check=True, capture_output=True,
    ).stdout
    return np.frombuffer(raw, np.float32).astype(np.float64)


def plain_arabic(text: str) -> str:
    """Letters only: no harakat, Quranic marks or tatweel; alef forms unified."""
    out = []
    for ch in unicodedata.normalize("NFKD", text):
        if unicodedata.category(ch) == "Mn" or ch in "\u0640ۙۚۛۗۖۘ۞":
            continue
        out.append(ch)
    s = "".join(out)
    s = re.sub("[أإآٱا]", "ا", s).replace("ى", "ي").replace("ة", "ه")
    return re.sub(r"[^\u0621-\u064A ]", "", s).strip()


# ---------------------------------------------------------------- analysis

@dataclass
class Part:
    index: int
    start: float  # cut points (s), padding included
    end: float
    speech_start: float
    speech_end: float
    group: int = -1
    asr: str = ""
    asr_label: str = ""
    asr_score: float = 0.0
    label: str = ""
    flags: list[str] = field(default_factory=list)


def frames(x: np.ndarray):
    n, hop = 1024, int(HOP * SR)
    f, t, z = signal.stft(x, SR, nperseg=n, noverlap=n - hop, boundary=None)
    return f, t + (n / 2) / SR - (n / 2) / SR, np.abs(z) ** 2


def runs(mask: np.ndarray):
    edges = np.flatnonzero(np.diff(np.r_[0, mask.astype(int), 0]))
    return list(zip(edges[::2], edges[1::2]))


def find_bells(x: np.ndarray):
    f, t, power = frames(x)
    band = (f >= BELL_BAND[0]) & (f <= BELL_BAND[1])
    ratio = power[band].sum(0) / (power.sum(0) + 1e-12)
    cands = [
        (t[a], t[b - 1])
        for a, b in runs(ratio > BELL_RATIO)
        if t[b - 1] - t[a] >= BELL_MIN_S
    ]
    if not cands:
        return [], []
    # Template = first candidate; each candidate must match it.
    s0 = cands[0][0]
    tmpl = x[int(s0 * SR): int((s0 + 0.9) * SR)]
    bells, scores = [], []
    for a, b in cands:
        seg = x[max(0, int((a - 0.2) * SR)): int((a + 1.2) * SR)]
        c = signal.correlate(seg, tmpl, "valid")
        energy = np.sqrt(np.convolve(seg ** 2, np.ones(len(tmpl)), "valid"))
        score = float((c / (energy * np.linalg.norm(tmpl) + 1e-12)).max())
        scores.append(round(score, 3))
        if score >= BELL_CORR:
            bells.append((a, b))
    return bells, scores


def loudness(x: np.ndarray):
    x = signal.sosfilt(signal.butter(2, 70, "hp", fs=SR, output="sos"), x)
    hop = int(HOP * SR)
    win = int(0.02 * SR)
    sq = np.convolve(x ** 2, np.ones(win) / win, "same")[::hop]
    return 10 * np.log10(sq + 1e-10)


def split(x: np.ndarray, bells):
    db = loudness(x)
    floor = np.percentile(db, 10)
    speech = db > floor + SPEECH_DB
    # Bells are not speech.
    for a, b in bells:
        speech[int((a - 0.05) / HOP): int((b + 0.1) / HOP) + 1] = False
    # Close tiny holes (< 0.35 s) inside speech, drop blips (< 0.12 s).
    for a, b in runs(~speech):
        if 0 < a and b < len(speech) and (b - a) * HOP < 0.35:
            speech[a:b] = True
    for a, b in runs(speech):
        if (b - a) * HOP < 0.12:
            speech[a:b] = False
    dur = len(x) / SR
    bounds = [0.0] + [v for a, b in bells for v in (a, b)] + [dur]
    parts = []
    for i in range(0, len(bounds), 2):
        lo, hi = bounds[i], bounds[i + 1]
        idx = np.flatnonzero(speech[int(lo / HOP): int(hi / HOP)])
        if not len(idx):
            continue
        s0 = lo + idx[0] * HOP
        s1 = lo + (idx[-1] + 1) * HOP
        start = max(lo + (0.06 if i else 0), s0 - PAD_S)
        end = min(hi - (0.06 if i + 2 < len(bounds) else 0), s1 + PAD_S)
        p = Part(len(parts), round(start, 3), round(end, 3),
                 round(s0, 3), round(s1, 3))
        if s1 - s0 < MIN_SEG_S:
            p.flags.append(f"çok kısa ({s1 - s0:.2f} sn)")
        # Speech near its peak at the very edge = maybe cut inside a word.
        seg_db = db[int(start / HOP): int(end / HOP)]
        peak = seg_db.max()
        for name, edge in (("baş", seg_db[:4]), ("son", seg_db[-4:])):
            if edge.max() > peak - EDGE_DB:
                p.flags.append(f"{name} kenarında yüksek ses (kelime kesilmiş olabilir)")
        # Bell energy left inside.
        f, t, power = frames(x[int(start * SR): int(end * SR)])
        band = (f >= BELL_BAND[0]) & (f <= BELL_BAND[1])
        ratio = power[band].sum(0) / (power.sum(0) + 1e-12)
        if any((b - a) * HOP > 0.2 for a, b in runs(ratio > BELL_RATIO)):
            p.flags.append("parçada zil kalıntısı")
        parts.append(p)
    return parts, floor


# ------------------------------------------------------------ repeat check

def logmel(x: np.ndarray) -> np.ndarray:
    f, _, power = frames(x)
    mels = 2595 * np.log10(1 + np.array([80, 7000]) / 700)
    pts = 700 * (10 ** (np.linspace(*mels, 42) / 2595) - 1)
    fb = np.zeros((40, len(f)))
    for i in range(40):
        lo, c, hi = pts[i: i + 3]
        fb[i] = np.clip(np.minimum((f - lo) / (c - lo), (hi - f) / (hi - c)), 0, None)
    m = np.log(fb @ power + 1e-10)[:, ::2]  # 50 frames/s
    m -= m.mean(1, keepdims=True)
    return m / (np.linalg.norm(m, axis=0, keepdims=True) + 1e-9)


def dtw(a: np.ndarray, b: np.ndarray) -> float:
    cost = 1 - a.T @ b  # cosine distance
    n, m = cost.shape
    acc = np.full((n + 1, m + 1), np.inf)
    acc[0, 0] = 0
    for i in range(1, n + 1):
        row = cost[i - 1]
        prev = acc[i - 1]
        cur = acc[i]
        for j in range(1, m + 1):
            cur[j] = row[j - 1] + min(prev[j], prev[j - 1], cur[j - 1])
    return float(acc[n, m] / (n + m))


def similarity(x: np.ndarray, parts: list[Part]):
    feats = [logmel(x[int(p.speech_start * SR): int(p.speech_end * SR)]) for p in parts]
    n = len(parts)
    d = np.zeros((n, n))
    for i in range(n):
        for j in range(i + 1, n):
            a, b = feats[i], feats[j]
            # Very different lengths cannot be the same verse.
            r = max(a.shape[1], b.shape[1]) / max(1, min(a.shape[1], b.shape[1]))
            d[i, j] = d[j, i] = dtw(a, b) if r < 1.8 else 1.0
    return d


def group_parts(parts: list[Part], d: np.ndarray):
    """Consecutive parts close to the group's first part = one group."""
    g = 0
    first = 0
    for i, p in enumerate(parts):
        if i and d[first, i] > GROUP_DTW * max(d.max(), 1e-9):
            g += 1
            first = i
        p.group = g


# --------------------------------------------------------------- recognition

_asr = None


def recognize(audio: np.ndarray) -> str | None:
    global _asr
    try:
        if _asr is None:
            from transformers import pipeline
            _asr = pipeline("automatic-speech-recognition",
                            model="tarteel-ai/whisper-base-ar-quran")
        audio16 = signal.resample_poly(audio, 160, 2205 // 10)
        return _asr({"raw": audio16.astype(np.float32), "sampling_rate": 16000})["text"]
    except Exception as e:  # model not installed / offline
        print(f"  tanıma yok: {e}", file=sys.stderr)
        _asr = False
        return None


def references(surah: int):
    data = json.loads(DIYANET.read_text(encoding="utf-8"))
    refs = {"istiaze": plain_arabic(ISTIAZE), "besmele": plain_arabic(BESMELE)}
    for key, v in sorted(data.items(), key=lambda kv: int(kv[0].split(":")[1])):
        s, a = map(int, key.split(":"))
        if s == surah:
            refs[f"ayet {a}"] = plain_arabic(v["text"])
    # The recordings end with the whole surah read once.
    refs["tam okuma"] = " ".join(v for k, v in refs.items() if k.startswith("ayet"))
    return refs


def best_match(text: str, refs: dict[str, str]):
    t = plain_arabic(text)
    scored = []
    for name, ref in refs.items():
        scored.append((SequenceMatcher(None, t, ref).ratio(), name))
        # The reader may join istiaze/besmele to a verse.
    return max(scored)


# -------------------------------------------------------------------- main

def encode(src: Path, start: float, end: float, out: Path) -> None:
    subprocess.run(
        [ffmpeg(), "-v", "error", "-y", "-ss", f"{start:.3f}", "-to", f"{end:.3f}",
         "-i", str(src), "-af",
         f"pan=mono|c0=0.5*c0+0.5*c1,volume={GAIN_DB}dB,afade=t=in:d=0.02,"
         f"afade=t=out:st={max(0, end - start - 0.03):.3f}:d=0.03",
         "-ar", "32000", "-c:a", "libmp3lame", "-b:a", "48k", "-map_metadata", "-1",
         str(out)],
        check=True,
    )


def peel_opening(x: np.ndarray, parts: list[Part], refs: dict[str, str]) -> None:
    """The recording starts without a bell: istiaze / besmele and the first
    reading of verse 1 are one part, split only by a pause. Peel off leading
    pause-separated chunks the recognizer confirms as istiaze or besmele."""
    if not parts:
        return
    db = loudness(x)
    floor = np.percentile(db, 10)
    while True:
        p = parts[0]
        lo, hi = int(p.speech_start / HOP), int(p.speech_end / HOP)
        quiet = [(a, b) for a, b in runs(db[lo:hi] <= floor + SPEECH_DB)
                 if (b - a) * HOP >= PEEL_PAUSE_S]
        if not quiet:
            return
        a, b = quiet[0]
        cut0, cut1 = p.speech_start + a * HOP, p.speech_start + b * HOP
        text = recognize(x[int(p.speech_start * SR): int(cut0 * SR)])
        if text is None:
            return
        score, label = best_match(text, {k: refs[k] for k in ("istiaze", "besmele")})
        if score < 0.8:
            return
        head = Part(0, p.start, round(min(cut1, cut0 + PAD_S), 3),
                    p.speech_start, round(cut0, 3), asr=text, asr_score=score,
                    asr_label=label)
        p.start = round(max(cut0, cut1 - PAD_S), 3)
        p.speech_start = round(cut1, 3)
        parts.insert(0, head)
        for i, q in enumerate(parts):
            q.index = i


def process(src: Path, surah: int, name: str, use_asr: bool = True) -> dict:
    print(f"{src.name} → {name}")
    x = decode(src)
    bells, bell_scores = find_bells(x)
    parts, floor = split(x, bells)
    refs = references(surah)
    if use_asr:
        peel_opening(x, parts, refs)
    d = similarity(x, parts)
    group_parts(parts, d)

    if use_asr:
        for p in parts:
            if p.asr:
                continue
            text = recognize(x[int(p.speech_start * SR): int(p.speech_end * SR)])
            if text is None:
                break
            p.asr = text
            p.asr_score, p.asr_label = best_match(text, refs)
        if all(p.asr for p in parts):
            # Groups from the recognized text (consecutive equal labels);
            # DTW only cross-checks that the repeats sound alike.
            g = -1
            for i, p in enumerate(parts):
                if not i or p.asr_label != parts[i - 1].asr_label:
                    g += 1
                p.group = g
            limit = GROUP_DTW * max(d.max(), 1e-9)
            for i, p in enumerate(parts):
                for j in range(i):
                    if parts[j].group == p.group and d[i, j] > limit:
                        p.flags.append(
                            f"parça {j + 1} ile ses benzerliği düşük (DTW {d[i, j]:.2f})")

    # Label per group: majority of the recognized labels; then the order
    # must follow the surah (istiaze, besmele, ayet 1, 2, ..., tam okuma).
    groups: dict[int, list[Part]] = {}
    for p in parts:
        groups.setdefault(p.group, []).append(p)
    order = list(refs)
    last = -1
    for g, members in groups.items():
        votes = [m.asr_label for m in members if m.asr_label and m.asr_score >= 0.5]
        label = max(set(votes), key=votes.count) if votes else ""
        if votes and votes.count(label) < len(members):
            for m in members:
                if m.asr_label != label:
                    m.flags.append(f"tanıma bu tekrarı '{m.asr_label}' sanıyor (grup: {label})")
        if not label:
            for m in members:
                m.flags.append("metin doğrulanamadı")
        elif order.index(label) <= last:
            for m in members:
                m.flags.append(f"sıra dışı: '{label}' önceki gruptan sonra gelmemeli")
        else:
            last = order.index(label)
        if len(members) != 3 and label not in ("istiaze", "besmele", "tam okuma", ""):
            for m in members:
                m.flags.append(f"grupta {len(members)} tekrar var (3 bekleniyordu)")
        for m in members:
            m.label = label
    # Verses never found.
    found = {p.label for p in parts}
    missing = [r for r in order if r.startswith("ayet") and r not in found]

    out = OUT / name
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob("*.mp3"):
        old.unlink()
    for p in parts:
        encode(src, p.start, p.end, out / f"parca_{p.index + 1:02d}.mp3")
    # The cleanest repeat of each label: fewest clipped samples (the
    # recordings are loud), then the widest silence margin, then the first.
    def cleanliness(p: Part):
        seg = x[int(p.start * SR): int(p.end * SR)]
        margin = min(p.speech_start - p.start, p.end - p.speech_end)
        return (int((np.abs(seg) > 0.98).sum()), -round(margin, 2), p.index)

    best: dict[str, Part] = {}
    for p in parts:
        if p.label and not p.flags and (
                p.label not in best or cleanliness(p) < cleanliness(best[p.label])):
            best[p.label] = p
    chosen = {}
    for label, p in best.items():
        fname = {"besmele": "00_besmele.mp3", "istiaze": "00_istiaze.mp3",
                 "tam okuma": "tam_okuma.mp3"}.get(label)
        fname = fname or f"{int(label.split()[1]):02d}_ayet.mp3"
        encode(src, p.start, p.end, out / fname)
        chosen[label] = p.index + 1

    report = {
        "kaynak": str(src),
        "sure": surah,
        "sure_kimligi": name,
        "sure_sn": round(len(x) / SR, 2),
        "zil": {"frekans_hz": BELL_HZ, "adet": len(bells),
                "zamanlar": [[round(a, 2), round(b, 2)] for a, b in bells],
                "sablon_korelasyonu": bell_scores},
        "gurultu_tabani_db": round(float(floor), 1),
        "parcalar": [asdict(p) for p in parts],
        "dtw": np.round(d, 3).tolist(),
        "secilen_tekrar": chosen,
        "bulunamayan": missing,
    }
    (out / "rapor.json").write_text(json.dumps(report, ensure_ascii=False, indent=1),
                                    encoding="utf-8")
    (out / "rapor.md").write_text(markdown(report), encoding="utf-8")
    return report


def markdown(r: dict) -> str:
    lines = [f"# {r['sure_kimligi']} ({r['sure']}. sure)", "",
             f"Kaynak: `{r['kaynak']}` ({r['sure_sn']} sn). "
             f"Zil: {r['zil']['adet']} adet, ~{BELL_HZ} Hz.", "",
             "| Parça | Süre (sn) | Konuşma | Grup | Etiket | Tanıma (benzerlik) | Uyarı |",
             "|---|---|---|---|---|---|---|"]
    for p in r["parcalar"]:
        lines.append(
            f"| {p['index'] + 1} | {p['start']:.2f}–{p['end']:.2f} | "
            f"{p['speech_end'] - p['speech_start']:.2f} | {p['group'] + 1} | "
            f"{p['label'] or '?'} | {p['asr']} ({p['asr_score']:.2f}) | "
            f"{'; '.join(p['flags']) or '—'} |")
    lines += ["", f"Seçilen tekrarlar: {r['secilen_tekrar']}",
              f"Bulunamayan: {r['bulunamayan'] or 'yok'}", ""]
    return "\n".join(lines)


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser()
    ap.add_argument("file", nargs="?")
    ap.add_argument("--surah", type=int)
    ap.add_argument("--name")
    ap.add_argument("--batch", action="store_true")
    ap.add_argument("--no-asr", action="store_true")
    a = ap.parse_args()
    jobs = []
    if a.batch:
        jobs = [(SOURCE_DIR / f, s, n) for f, (s, n) in SURAHS.items()]
    else:
        src = Path(a.file)
        s, n = SURAHS.get(src.name, (a.surah, a.name or src.stem))
        jobs = [(src, a.surah or s, a.name or n)]
    summary = []
    for src, s, n in jobs:
        r = process(src, s, n, use_asr=not a.no_asr)
        flagged = sum(1 for p in r["parcalar"] if p["flags"])
        summary.append((n, len(r["parcalar"]), r["zil"]["adet"], flagged, r["bulunamayan"]))
    for n, parts, bells, flagged, missing in summary:
        print(f"{n}: {parts} parça, {bells} zil, {flagged} şüpheli, eksik: {missing or '-'}")


if __name__ == "__main__":
    main()
