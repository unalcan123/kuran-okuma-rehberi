"""Bir dua kartı resmini kurar (yazısız, dikey; listede numara üstte, başlık altta).

    python tool/install_dua_card.py 12 12_namaz_tesbihati ref/resim.png

- asıl -> assets_src/chatgpt_kartlar/NN_yeni.png (pakete girmez)
- ortadan 296:336'ya kırpılır, 296×336, yuvarlak köşe
  -> assets/images/lessons/yazisiz/dualar/dua_NN.png (kDuaCardImageSize)
- kDuaTextFreeImages'a bağlar (eski kart yerinde kalır).
Resimde yazı olmamalı (numarayı ve başlığı uygulama yazar); gözle kontrol et.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "lib/data/recitation_card_images.dart"
W, H = 296, 336


def main(n: int, dua_id: str, src: str) -> None:
    im = Image.open(src).convert("RGB")
    (ROOT / "assets_src/chatgpt_kartlar").mkdir(parents=True, exist_ok=True)
    im.save(ROOT / f"assets_src/chatgpt_kartlar/{n:02d}_yeni.png")
    w, h = im.size
    if w / h > W / H:
        nw = round(h * W / H)
        im = im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    else:
        nh = round(w * H / W)
        im = im.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))
    im = im.resize((W, H), Image.LANCZOS).convert("RGBA")
    m = Image.new("L", (W * 4, H * 4), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, W * 4 - 1, H * 4 - 1], radius=48, fill=255)
    im.putalpha(m.resize((W, H), Image.LANCZOS))
    im.save(ROOT / f"assets/images/lessons/yazisiz/dualar/dua_{n:02d}.png", optimize=True)

    s = DATA.read_text(encoding="utf-8")
    s = re.sub(rf"  '{dua_id}': '\$_yazisiz/dualar/dua_\d+\.png',\n", "", s)
    imgs = re.search(r"const Map<String, String> kDuaTextFreeImages = \{\n(.*?)\};", s, re.S)
    lines = imgs.group(1).splitlines(keepends=True) + [f"  '{dua_id}': '$_yazisiz/dualar/dua_{n:02d}.png',\n"]
    lines.sort(key=lambda e: int(re.match(r"  '(\d+)_", e).group(1)))
    s = s[:imgs.start(1)] + "".join(lines) + s[imgs.end(1):]
    DATA.write_text(s, encoding="utf-8")
    print(f"dua_{n:02d}.png {W}x{H} (kaynak {w}x{h})")


if __name__ == "__main__":
    main(int(sys.argv[1]), sys.argv[2], sys.argv[3])
