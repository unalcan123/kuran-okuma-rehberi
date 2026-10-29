"""Onaylanmış klipleri uygulamaya kurar (Asr'da elle yapılanın aynısı).

    python tool/ezber_split/install_clips.py duha insirah ... ayetel-kursi 10_ezan_duasi

Kaynak tmp/ezber_split/<id>/ (split_ezber.py çıktısı). Yalnız raporda
şüphesiz seçilmiş klibi olan öğe kurulur; bir ayeti eksik olan sure hiç
kurulmaz (yanlış/eksik eşleşme yerine metin kartı kalır).

- Sure: 00_besmele.mp3 + NN_ayet.mp3 → assets/audio/sureler/<order>_<id>/
- Dua (tek bölüm): 01_bolum.mp3 → assets/audio/dualar/<id>/
- veri dosyasında ses yolları, pubspec.yaml klasörü,
  tool/original_audio_fingerprints.json parmak izleri yazılır;
- bütün bölümlerin sesi varsa öğe kFullReadingAudio'dan çıkar (Dinle bölüm
  bölüm çalar ve okunan kartı vurgular); uzun kayıt ve manifest satırı silinir.
"""

from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPLIT = ROOT / "tmp" / "ezber_split"
SURAH_DATA = [ROOT / "lib/data/supplementary_sureler_data.dart",
              ROOT / "lib/data/ayetel_kursi_data.dart"]
DUA_DATA = ROOT / "lib/data/additional_dualar_data.dart"
FULL = ROOT / "lib/data/full_reading_audio.dart"
MANIFEST = ROOT / "tool/sources/audio_import_manifest.json"
FINGERPRINTS = ROOT / "tool/original_audio_fingerprints.json"
PUBSPEC = ROOT / "pubspec.yaml"


def fingerprint(b: bytes) -> str:
    h = 0x811C9DC5
    for x in b:
        h = ((h ^ x) * 0x01000193) & 0xFFFFFFFF
    return f"{len(b)}:{h:08x}"


def chosen_labels(item: str) -> set[str]:
    r = json.loads((SPLIT / item / "rapor.json").read_text(encoding="utf-8"))
    if "secilen_tekrar" in r:
        return set(r["secilen_tekrar"])
    return set(r["secilen"])


def set_asset(block: str, after: str, field: str, value: str) -> str:
    """The first `field: '...'` after `after` gets `value` (empty or a
    previous install's path)."""
    i = block.index(after)
    m = re.compile(rf"{field}: (['\"])[^'\"]*\1").search(block, i)
    return block[:m.start()] + f"{field}: '{value}'" + block[m.end():]


def register(folder: Path, asset_dir: str, group: str) -> None:
    pub = PUBSPEC.read_text(encoding="utf-8")
    line = f"    - assets/{asset_dir}/\n"
    if line not in pub:
        entries = re.findall(rf"    - assets/audio/{group}/[^\n]+/\n", pub)
        ordered = sorted(entries + [line])
        k = ordered.index(line)
        anchor = ordered[k - 1] if k else entries[0]
        pub = pub.replace(anchor, anchor + line if k else line + anchor, 1)
        PUBSPEC.write_text(pub, encoding="utf-8")
    fp = json.loads(FINGERPRINTS.read_text(encoding="utf-8"))
    for f in sorted(folder.glob("*.mp3")):
        fp["files"][f.relative_to(ROOT).as_posix()] = fingerprint(f.read_bytes())
    FINGERPRINTS.write_text(json.dumps(fp, ensure_ascii=False, indent=1), encoding="utf-8")


def drop_full_reading(item: str) -> None:
    full = FULL.read_text(encoding="utf-8")
    m = re.search(rf"  '{re.escape(item)}': 'audio/full_readings/([^']+)',\n", full)
    if not m:
        return
    FULL.write_text(full.replace(m.group(0), ""), encoding="utf-8")
    (ROOT / "assets/audio/full_readings" / m.group(1)).unlink(missing_ok=True)
    rows = [r for r in json.loads(MANIFEST.read_text(encoding="utf-8")) if r["id"] != item]
    MANIFEST.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def install_surah(sid: str) -> None:
    for path in SURAH_DATA:
        s = path.read_text(encoding="utf-8")
        m = re.search(r"const \w+ = Surah\(\s*order: (\d+),\s*id: [\"']"
                      + re.escape(sid) + "[\"']", s)
        if m:
            break
    else:
        raise SystemExit(f"{sid}: veride yok")
    start, end, order = m.start(), s.find("\n);\n", m.start()) + 4, int(m.group(1))
    block = s[start:end]
    numbers = [int(n) for n in re.findall(r"number: (\d+),", block)]
    labels = chosen_labels(sid)
    single = len(numbers) == 1 and "tam metin" in labels
    missing = [n for n in numbers if not single and f"ayet {n}" not in labels]
    if missing or not numbers or (len(numbers) == 1 and not single and f"ayet {numbers[0]}" not in labels):
        print(f"{sid}: seçilmiş klibi olmayan ayet(ler) {missing or numbers}; KURULMADI")
        return
    folder = f"{order:02d}_{sid}"
    out = ROOT / "assets/audio/sureler" / folder
    out.mkdir(parents=True, exist_ok=True)
    asset = f"audio/sureler/{folder}"
    for n in numbers:
        name = f"{n:02d}_ayet.mp3"
        shutil.copyfile(SPLIT / sid / name, out / name)
        block = set_asset(block, f"number: {n},", "audioAsset", f"{asset}/{name}")
    besmele = "besmele" in labels and (SPLIT / sid / "00_besmele.mp3").exists()
    if besmele:
        shutil.copyfile(SPLIT / sid / "00_besmele.mp3", out / "00_besmele.mp3")
        block = set_asset(block, "besmele", "besmeleAudioAsset", f"{asset}/00_besmele.mp3")
    path.write_text(s[:start] + block + s[end:], encoding="utf-8")
    register(out, asset, "sureler")
    if "AudioAsset: ''" not in block and "audioAsset: ''" not in block:
        drop_full_reading(sid)
    print(f"{sid}: {len(numbers)} ayet{' + besmele' if besmele else ' (besmele sesi yok)'} → assets/{asset}")


def install_dua(did: str) -> None:
    if "tam metin" not in chosen_labels(did):
        print(f"{did}: seçilmiş klip yok; KURULMADI")
        return
    s = DUA_DATA.read_text(encoding="utf-8")
    start = s.index(f'id: "{did}"')
    end = s.find("\n  Dua(", start)
    end = len(s) if end < 0 else end
    block = s[start:end]
    if len(re.findall(r"DuaSegment\(", block)) != 1:
        print(f"{did}: birden çok bölüm; tek klip bağlanamaz, KURULMADI")
        return
    out = ROOT / "assets/audio/dualar" / did
    out.mkdir(parents=True, exist_ok=True)
    asset = f"audio/dualar/{did}"
    shutil.copyfile(SPLIT / did / "01_bolum.mp3", out / "01_bolum.mp3")
    block = set_asset(block, "DuaSegment(", "audioAsset", f"{asset}/01_bolum.mp3")
    DUA_DATA.write_text(s[:start] + block + s[end:], encoding="utf-8")
    register(out, asset, "dualar")
    drop_full_reading(did)
    print(f"{did}: 1 bölüm → assets/{asset}")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    for item in sys.argv[1:]:
        (install_dua if re.match(r"\d+_", item) else install_surah)(item)
