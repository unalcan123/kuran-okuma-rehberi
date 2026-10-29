"""Uygulamadaki ayet kliplerini bağımsız olarak doğrular.

    python tool/ezber_split/verify_clips.py duha insirah ...

Her klip (assets/audio/sureler/<order>_<id>/) yeniden çözülür ve:
- tanıma, kartın kendi ayet metniyle en iyi eşleşmeli (başka ayet değil),
- zil yok (zil bandının baskın olduğu 0,2 sn'den uzun bölüm yok),
- baş ve son kenar sessiz (kelime kesilmemiş),
- 00_besmele.mp3 besmele olarak tanınmalı.
Sonuç tmp/ezber_split/dogrulama.md'ye yazılır; hata varsa çıkış kodu 1.
"""

from __future__ import annotations

import re
import sys
from difflib import SequenceMatcher
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import split_ezber as s  # noqa: E402

ROOT = s.ROOT


def main(ids: list[str]) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    surah_no = {name: no for _, (no, name) in s.SURAHS.items()}
    surah_no["ayetel-kursi"] = 2
    lines = ["# Klip doğrulaması", "",
             "| Sure | Dosya | Süre (sn) | Beklenen | Tanınan en iyi | Benzerlik | Zil | Kenar | Sonuç |",
             "|---|---|---|---|---|---|---|---|---|"]
    bad = 0
    for sid in ids:
        folder = next((ROOT / "assets/audio/sureler").glob(f"*_{sid}"), None)
        if folder is None:
            lines.append(f"| {sid} | — | | | | | | | kurulu değil |")
            continue
        refs = s.references(surah_no[sid], sid)
        if sid == "ayetel-kursi":
            text = s.app_text("lib/data/ayetel_kursi_data.dart", sid)
            refs = {"istiaze": s.plain_arabic(s.ISTIAZE), "besmele": s.plain_arabic(s.BESMELE),
                    "ayet 255": s.plain_arabic(text)}
        refs.pop("tam okuma", None)
        for f in sorted(folder.glob("*.mp3")):
            m = re.match(r"(\d+)_(ayet|besmele)", f.stem)
            expected = "besmele" if m.group(2) == "besmele" else f"ayet {int(m.group(1))}"
            x = s.decode(f)
            txt = s.recognize(x) or ""
            score, label = s.best_match(txt, refs)
            own = SequenceMatcher(None, s.plain_arabic(txt), refs[expected]).ratio()
            fr, _, power = s.frames(x)
            band = (fr >= s.BELL_BAND[0]) & (fr <= s.BELL_BAND[1])
            ratio = power[band].sum(0) / (power.sum(0) + 1e-12)
            bell = max([(b - a) * s.HOP for a, b in s.runs(ratio > s.BELL_RATIO)] or [0])
            db = s.loudness(x)
            edge = max(db[:4].max(), db[-4:].max()) - db.max()
            ok = label == expected and own >= 0.8 and bell < 0.2 and edge < -s.EDGE_DB
            bad += not ok
            lines.append(
                f"| {sid} | {f.name} | {len(x) / s.SR:.2f} | {expected} | {label} | "
                f"{own:.2f} | {bell:.2f} sn | {edge:.0f} dB | {'tamam' if ok else 'HATA'} |")
            print(lines[-1])
    lines += ["", f"Hatalı klip: {bad}", ""]
    (s.OUT / "dogrulama.md").write_text("\n".join(lines), encoding="utf-8")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
