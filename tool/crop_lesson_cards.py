"""Kart görsellerini master görsellerden ayrı PNG'lere kırpar (deterministik).

    python tool/crop_lesson_cards.py

Ders, sure ve dua listelerinin kartları aynı yöntemle kırpılır (MASTERS):

- assets/images/lessons/lesson_cards_master.png → cards/{intro_…,lesson_NN}.png
- assets/images/lessons/duakartlari.png         → dualar/dua_NN.png
- assets/images/lessons/sure kartlari.png       → sureler/sure_NN.png
  (son satırı ortalanmış 2 geniş kart: row_col_edges)

Görsel yeniden üretilmez; yalnız kırpılır. Master bir ızgaradır; her ızgara
hücresinde kartın sıkı sınırı, arka plandan ayrışan pikseller + beyaz
çerçeveden bulunur; komşu hücreye taşmamak için arama penceresi kart arası
boşlukların ortasıyla sınırlıdır. Kartın yuvarlak köşelerinin dışı saydam
yapılır, böylece kart her zeminde temiz görünür.

Master'daki bir kart uygulamanın verisiyle uyuşmuyorsa (yanlış sure/dua) adı
None bırakılır: o kart kırpılmaz, uygulamaya bağlanmaz.
"""

import sys
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
from PIL import Image

LESSONS = Path("assets/images/lessons")


@dataclass
class Master:
    source: Path
    out: Path
    # Background color (between the cards).
    bg: tuple[int, int, int]
    # Midpoints of the gaps between cards (window edges).
    col_edges: list[int]
    row_edges: list[int]
    # Output name of each cell, left to right, top to bottom; None = skip.
    names: list[str | None]
    # Corner radius of the cards (measured).
    radius: float
    # A pixel brighter than this in every channel counts as the white frame.
    white: int = 242
    # Wider windows for single cards: name → right edge of its window.
    window_right: dict[str, int] = field(default_factory=dict)
    # Rows laid out differently (row index → its own col_edges), e.g. a
    # centred last row of wider cards.
    row_col_edges: dict[int, list[int]] = field(default_factory=dict)


MASTERS = [
    # 1536x1024, 6 x 6 (last row 4). Columns 14-258, 267-515, 524-766,
    # 775-1014, 1022-1266, 1275-1521; rows 8-176, 184-342, 350-525, 533-697,
    # 704-863, 871-1018. Ders 30 is not in it (SINGLE_SOURCES).
    Master(
        source=LESSONS / "lesson_cards_master.png",
        out=LESSONS / "cards",
        bg=(253, 245, 228),
        col_edges=[0, 262, 519, 770, 1018, 1270, 1536],
        row_edges=[0, 180, 346, 529, 700, 867, 1024],
        names=["intro_harflerin_cikis_yerleri"]
        + [f"lesson_{n:02d}" for n in list(range(1, 30)) + [31, 32, 33, 34]],
        radius=16,
        # Ders 34 is wider than its column; nothing is to its right.
        window_right={"lesson_34": 1270},
    ),
    # 1536x1024, 3 x 3. Columns 16-506, 524-1015, 1033-1522; rows 9-327,
    # 342-657, 670-997. "Dua 1" … "Dua 9" in the app's order (kDualar).
    Master(
        source=LESSONS / "duakartlari.png",
        out=LESSONS / "dualar",
        bg=(254, 250, 238),
        col_edges=[0, 514, 1024, 1536],
        row_edges=[0, 334, 663, 1024],
        names=[f"dua_{n:02d}" for n in range(1, 10)],
        radius=20,
        white=248,
    ),
    # 1536x1024: 3 rows of 3 (columns 17-508, 528-1007, 1029-1519; rows
    # 9-265, 278-520, 533-763), then a centred row of 2 wider cards
    # (167-756, 778-1367; 773-1000). "Sure 1" … "Sure 11" = kSureler in order
    # (Fatiha, Fil, Kureyş, Maun, İhlas, Kevser, Nas, Felak, Nasr, Tebbet,
    # Kafirun) — checked card by card.
    Master(
        source=LESSONS / "sure kartlari.png",
        out=LESSONS / "sureler",
        bg=(254, 249, 235),
        col_edges=[0, 518, 1018, 1536],
        row_edges=[0, 271, 527, 768, 1024],
        row_col_edges={3: [0, 767, 1536]},
        names=[f"sure_{n:02d}" for n in range(1, 12)],
        radius=20,
        white=248,
    ),
]


def card_box(master: Master, im: np.ndarray, x0: int, y0: int, x1: int, y1: int):
    """Tight box of the card inside the window (x0..x1, y0..y1)."""
    win = im[y0:y1, x0:x1]
    diff = np.abs(win - np.array(master.bg)).sum(2)
    white = (win > master.white).all(2)
    # Card pixels: the white frame or clearly colored art (not the faint
    # grey shadow, which differs from the background by < ~60).
    card = white | (diff > 60)
    rows = np.where(card.mean(1) > 0.35)[0]
    cols = np.where(card.mean(0) > 0.35)[0]
    return x0 + cols[0], y0 + rows[0], x0 + cols[-1] + 1, y0 + rows[-1] + 1


def clear_corners(rgba: np.ndarray, radius: float) -> None:
    """Outside the card's rounded corners → transparent (the same geometric
    arc on every card, soft-edged; nothing inside the card is touched)."""
    h, w = rgba.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w].astype(float) + 0.5
    # Distance from each pixel to the nearest corner's circle centre, only
    # in the corner squares.
    cx = np.where(xs < radius, radius, np.where(xs > w - radius, w - radius, xs))
    cy = np.where(ys < radius, radius, np.where(ys > h - radius, h - radius, ys))
    dist = np.hypot(xs - cx, ys - cy)
    alpha = np.clip(radius + 0.5 - dist, 0, 1)
    rgba[..., 3] = (rgba[..., 3] * alpha).astype(np.uint8)


def crop_master(master: Master) -> None:
    image = Image.open(master.source).convert("RGB")
    print(f"{master.source.name}: {image.size[0]}x{image.size[1]}")
    im = np.asarray(image).astype(int)
    master.out.mkdir(parents=True, exist_ok=True)
    # Cells left to right, top to bottom (a row may have its own columns).
    cells = [
        (r, c, edges)
        for r in range(len(master.row_edges) - 1)
        for edges in [master.row_col_edges.get(r, master.col_edges)]
        for c in range(len(edges) - 1)
    ]
    for (r, c, edges), name in zip(cells, master.names):
        if name is None:
            print(f"  hücre {r + 1}.{c + 1}: uygulamayla uyuşmuyor, kırpılmadı")
            continue
        x0 = edges[c]
        x1 = master.window_right.get(name, edges[c + 1])
        box = card_box(
            master, im, x0, master.row_edges[r], x1, master.row_edges[r + 1]
        )
        crop = np.asarray(image.crop(box).convert("RGBA")).copy()
        clear_corners(crop, master.radius)
        Image.fromarray(crop).save(master.out / f"{name}.png", optimize=True)
        w, h = box[2] - box[0], box[3] - box[1]
        print(f"  {name}.png  {w}x{h}  ({w / h:.3f})  box={box}")


# Cards supplied as their own picture (not in the master): source (outside the
# app bundle, assets_src/ is not packaged), the card's white frame in it
# (measured), its corner radius, and the width to save at (sharper than the
# master cards' ~245 px, still < 200 KB).
SINGLE_SOURCES = {
    "lesson_30": (
        Path("assets_src/lessons/lesson_30_source.png"),  # 1536x1024
        (42, 64, 1489, 956),
        78,
        400,
    ),
}


def crop_single(name: str) -> None:
    source, box, radius, width = SINGLE_SOURCES[name]
    if not source.exists():
        print(f"{name}.png  kaynak yok ({source}), atlandı")
        return
    card = Image.open(source).convert("RGBA").crop(box)
    rgba = np.asarray(card).copy()
    clear_corners(rgba, radius)
    card = Image.fromarray(rgba)
    height = round(card.height * width / card.width)
    card = card.resize((width, height), Image.LANCZOS)
    card.save(LESSONS / "cards" / f"{name}.png", optimize=True)
    print(f"  {name}.png  {width}x{height}  ({width / height:.3f})  "
          f"kaynak {source.name} box={box}")


# Decorative pieces cut from design sheets (no text in them): source, box,
# output. The sure/dua reading screen's header scene comes from the design
# mockup's top-left panel, below its title (mosque, boy with a Mushaf,
# stream, flowers).
DECOR_CROPS = [
    (
        LESSONS / "dua ve sure sayfalari icin Görsel.png",  # 1024x1536
        (0, 176, 572, 544),
        Path("assets/images/reading/reading_scene.webp"),
    ),
]


def crop_decor() -> None:
    for source, box, out in DECOR_CROPS:
        out.parent.mkdir(parents=True, exist_ok=True)
        piece = Image.open(source).convert("RGB").crop(box)
        piece.save(out, quality=86, method=6)
        print(f"  {out.name}  {piece.width}x{piece.height}  box={box}")


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")  # Windows konsolu: Türkçe çıktı
    for master in MASTERS:
        crop_master(master)
    for name in SINGLE_SOURCES:
        crop_single(name)
    crop_decor()


if __name__ == "__main__":
    main()
