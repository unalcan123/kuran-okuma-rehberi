"""Cut the chosen repeats of the slow 2011 recordings (H:/Music/sureler/2, 3)
down to the reading itself: each part holds the reading, then a silence for
the child to repeat, and bell remnants at its edges."""
import json, subprocess, sys
from difflib import SequenceMatcher
from pathlib import Path
import numpy as np
sys.path.insert(0, "tool/ezber_split")
import split_ezber as se

SR = se.SR
OUT = Path("tmp/yeni")


def main_speech(x):
    fr = int(SR * 0.01); n = len(x) // fr
    db = 20 * np.log10(np.sqrt((x[:n * fr].reshape(n, fr) ** 2).mean(1)) + 1e-9)
    on = db > db.max() - 30
    runs, s = [], None
    for i, v in enumerate(list(on) + [False]):
        if v and s is None: s = i
        if not v and s is not None:
            if i - s >= 3: runs.append([s, i])
            s = None
    merged = []
    for a, b in runs:
        if merged and a - merged[-1][1] < 60: merged[-1][1] = b
        else: merged.append([a, b])
    main = max(merged, key=lambda r: r[1] - r[0])
    # quiet words a little apart from the main run stay with it
    for a, b in merged:
        if b <= main[0] and main[0] - b < 100 and b - a >= 30: main[0] = a
        if a >= main[1] and a - main[1] < 100 and b - a >= 30: main[1] = b
    return main[0] / 100, main[1] / 100, [(a / 100, b / 100) for a, b in merged]


def cut(src, part, out, window=None):
    seg_s, seg_e = part["start"], part["end"]
    if window:
        seg_s, seg_e = seg_s + window[0], part["start"] + window[1]
    raw = subprocess.run(["ffmpeg", "-v", "error", "-ss", str(seg_s), "-to", str(seg_e), "-i", str(src),
                          "-af", "pan=mono|c0=0.5*c0+0.5*c1", "-ar", str(SR), "-f", "f32le", "-"],
                         check=True, capture_output=True).stdout
    x = np.frombuffer(raw, np.float32).astype(np.float64)
    a, b, runs = main_speech(x)
    a = max(0.0, a - 0.15); b = min(len(x) / SR, b + 0.3)
    dur = b - a
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", f"{seg_s + a:.3f}", "-t", f"{dur:.3f}", "-i", str(src),
                    "-af", f"pan=mono|c0=0.5*c0+0.5*c1,afade=t=in:d=0.008,afade=t=out:st={dur - 0.04:.3f}:d=0.04",
                    "-ar", "32000", "-c:a", "libmp3lame", "-b:a", "48k", "-map_metadata", "-1", str(out)], check=True)
    return dur, runs


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    # id -> {output name: (part no., expected text)}; expected = Diyanet text
    # (phrases: the words the reader reads, from the recognition).
    plan = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    for sid, clips in plan.items():
        rep = json.loads((Path("tmp/ezber_split") / sid / "rapor.json").read_text(encoding="utf-8"))
        src = Path(rep["kaynak"])
        parts = {i + 1: p for i, p in enumerate(rep["parcalar"])}
        for name, (no, expected, *window) in clips.items():
            out = OUT / sid / name
            dur, runs = cut(src, parts[no], out, window or None)
            heard = se.recognize(se.decode(out)) or ""
            r = SequenceMatcher(None, se.plain_arabic(heard), se.plain_arabic(expected)).ratio()
            flag = "" if r >= 0.9 else "  <-- KONTROL"
            print(f"{sid}/{name} parça {no} {dur:.2f} sn benzerlik {r:.2f} | {heard}{flag}", flush=True)
