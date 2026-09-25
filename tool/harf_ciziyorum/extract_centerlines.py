"""Harf Çiziyorum: Hasenat yazı tipinden harflerin merkez çizgisi taslağını çıkarır.

Yalnızca geliştirme aracı (uygulama bunu çalıştırmaz). Her harf tek başına
biçimiyle büyük çizilir; küçük bileşenler nokta, büyük bileşen gövde sayılır;
gövde iskeletlenir (skimage.skeletonize) ve uç/kavşak noktaları arasındaki
kenarlar çıkarılır. Çıktı:
  build/harf_ciz/edges.json   harf başına kenar listeleri + nokta merkezleri
  build/harf_ciz/<id>.png     glif (gri) + kenarlar (renkli, numaralı)
Kenarlardan kalem hareketlerini ve önerilen yönleri elle seçip
lib/screens/oyunlar/harf_ciziyorum/ciz_models.dart'a yazarız; model
koordinatları bu aracın normalleştirmesiyle aynıdır (bkz. normalize()).

Gerekenler: pip install pillow numpy scikit-image
Çalıştırma: python tool/harf_ciziyorum/extract_centerlines.py
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from skimage.measure import label, regionprops
from skimage.morphology import skeletonize

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
FONT = os.path.join(ROOT, 'assets', 'fonts', 'Hasenat.ttf')
OUT = os.path.join(ROOT, 'build', 'harf_ciz')

# kArabicLetters sırası (id = sıra).
LETTERS = 'ابتثجحخدذرزسشصضطظعغفقكلمنوهي'
SIZE = 520  # font size (px)

# Tek başına biçimdeki nokta sayısı ve yeri (Arapça imlanın kesin kuralı; tahmin
# değil). Bitişik değen noktalar tek bileşen görünebildiği için işaret
# pikselleri bu sayıya kümelenir.
EXPECTED_DOTS = {2: 1, 3: 2, 4: 3, 5: 1, 7: 1, 9: 1, 11: 1, 13: 3, 15: 1,
                 17: 1, 19: 1, 20: 1, 21: 2, 25: 1, 28: 2}


def kmeans(points, k, iters=30):
    pts = np.asarray(points, float)
    # en uzak noktalarla başlat
    centers = [pts[0]]
    for _ in range(1, k):
        d = np.min([np.linalg.norm(pts - c, axis=1) for c in centers], axis=0)
        centers.append(pts[int(np.argmax(d))])
    centers = np.array(centers)
    for _ in range(iters):
        lab = np.argmin([np.linalg.norm(pts - c, axis=1) for c in centers], axis=0)
        centers = np.array([pts[lab == j].mean(axis=0) for j in range(k)])
    return centers, lab
CANVAS = 900
MARGIN = 0.12  # model kutusundaki boşluk


def render(ch):
    img = Image.new('L', (CANVAS, CANVAS), 0)
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, SIZE)
    d.text((CANVAS / 2, CANVAS / 2), ch, font=font, fill=255, anchor='mm')
    return np.array(img) > 127


def normalizer(mask):
    ys, xs = np.nonzero(mask)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    w, h = x1 - x0 + 1, y1 - y0 + 1
    side = max(w, h) / (1 - 2 * MARGIN)
    ox = x0 - (side - w) / 2
    oy = y0 - (side - h) / 2

    def norm(x, y):
        return (round((x - ox) / side, 4), round((y - oy) / side, 4))

    return norm, side


NB = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]


def edges_of(skel):
    pts = set(zip(*np.nonzero(skel)))

    def nbrs(p):
        return [(p[0] + dy, p[1] + dx) for dy, dx in NB if (p[0] + dy, p[1] + dx) in pts]

    deg = {p: len(nbrs(p)) for p in pts}
    nodes = {p for p in pts if deg[p] != 2}
    seen = set()
    edges = []
    for n in nodes:
        for q in nbrs(n):
            if (n, q) in seen:
                continue
            path = [n, q]
            seen.add((n, q))
            seen.add((q, n))
            prev, cur = n, q
            while cur not in nodes:
                nxt = [r for r in nbrs(cur) if r != prev and (cur, r) not in seen]
                if not nxt:
                    break
                r = nxt[0]
                seen.add((cur, r))
                seen.add((r, cur))
                path.append(r)
                prev, cur = cur, r
            edges.append(path)
    # yalın döngüler (hiç düğüm yok)
    rest = pts - {p for e in edges for p in e}
    while rest:
        start = next(iter(rest))
        path = [start]
        prev, cur = None, start
        while True:
            nxt = [r for r in nbrs(cur) if r != prev and r in rest and r not in path[1:]]
            if not nxt:
                break
            prev, cur = cur, nxt[0]
            if cur == start:
                break
            path.append(cur)
        path.append(start)
        edges.append(path)
        rest -= set(path)
    return edges


def rdp(points, eps):
    if len(points) < 3:
        return points
    a, b = np.array(points[0], float), np.array(points[-1], float)
    ab = b - a
    n = np.linalg.norm(ab)
    best, idx = -1, 0
    for i in range(1, len(points) - 1):
        p = np.array(points[i], float)
        d = np.linalg.norm(p - a) if n == 0 else abs(ab[0] * (p - a)[1] - ab[1] * (p - a)[0]) / n
        if d > best:
            best, idx = d, i
    if best > eps:
        return rdp(points[: idx + 1], eps)[:-1] + rdp(points[idx:], eps)
    return [points[0], points[-1]]


def main():
    os.makedirs(OUT, exist_ok=True)
    result = {}
    for i, ch in enumerate(LETTERS):
        lid = i + 1
        mask = render(ch)
        norm, side = normalizer(mask)
        lab = label(mask, connectivity=2)
        regions = sorted(regionprops(lab), key=lambda r: -r.area)
        body_area = regions[0].area
        body = np.zeros_like(mask)
        dots = []
        mark_px = []
        for r in regions:
            if r.area >= body_area * 0.3:
                body[lab == r.label] = True
            else:
                mark_px.extend(r.coords.tolist())
        need = EXPECTED_DOTS.get(lid, 0)
        if need and len(mark_px) >= need:
            centers, which = kmeans([(x, y) for (y, x) in mark_px], need)
            arr = np.array([(x, y) for (y, x) in mark_px], float)
            for j, c in enumerate(centers):
                ext = arr[which == j]
                size = max(np.ptp(ext[:, 0]), np.ptp(ext[:, 1])) + 1
                dots.append({'center': norm(c[0], c[1]), 'size': round(size / side, 4)})
        elif mark_px:
            print(f'UYARI {lid} {ch}: noktasız harfte {len(mark_px)} işaret pikseli')
        skel = skeletonize(body)
        edges = []
        for e in edges_of(skel):
            if len(e) < side * 0.03:  # iskeletin kısa kılçıkları
                continue
            simp = rdp([(x, y) for (y, x) in e], side * 0.006)
            edges.append([norm(x, y) for (x, y) in simp])
        # kalem kalınlığı ~ gövde alanı / iskelet uzunluğu
        stroke_w = float(body.sum()) / max(1, skel.sum()) / side
        result[lid] = {'char': ch, 'edges': edges, 'dots': dots, 'penWidth': round(stroke_w, 4)}

        # kontrol görüntüsü
        vis = Image.new('RGB', (CANVAS, CANVAS), 'white')
        vis.paste((200, 200, 200), mask=Image.fromarray((mask * 255).astype(np.uint8)))
        d = ImageDraw.Draw(vis)
        ys, xs = np.nonzero(mask)
        colors = ['red', 'blue', 'green', 'orange', 'purple', 'brown', 'magenta', 'teal']
        ox_side = side

        def back(p):
            # norm -> pixel
            (nx, ny) = p
            ys_, xs_ = np.nonzero(mask)
            x0, x1, y0, y1 = xs_.min(), xs_.max(), ys_.min(), ys_.max()
            w, h = x1 - x0 + 1, y1 - y0 + 1
            ox = x0 - (ox_side - w) / 2
            oy = y0 - (ox_side - h) / 2
            return (nx * ox_side + ox, ny * ox_side + oy)

        for k, e in enumerate(edges):
            pts = [back(p) for p in e]
            d.line(pts, fill=colors[k % len(colors)], width=5)
            d.ellipse([pts[0][0] - 9, pts[0][1] - 9, pts[0][0] + 9, pts[0][1] + 9], outline='black', width=3)
            d.text((pts[0][0] + 10, pts[0][1] - 20), f'{k}a', fill='black')
            d.text((pts[-1][0] + 10, pts[-1][1] + 5), f'{k}b', fill='black')
        for dot in dots:
            x, y = back(dot['center'])
            d.ellipse([x - 12, y - 12, x + 12, y + 12], outline='red', width=4)
        vis.save(os.path.join(OUT, f'{lid:02d}.png'))
    with open(os.path.join(OUT, 'edges.json'), 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=1)
    for lid, r in result.items():
        print(lid, r['char'], 'edges', len(r['edges']), [len(e) for e in r['edges']], 'dots', len(r['dots']), 'pen', r['penWidth'])

# ---------------------------------------------------------------------------
# Kalem hareketi tarifleri
#
# Her harf: kalem hareketlerinin listesi; her hareket, iskelet üzerinde sırayla
# geçilecek noktalar. Nokta = (x, y) normalleştirilmiş koordinat (en yakın
# iskelet pikseline oturtulur) ya da ('e', kenar, oran) = kenarın o oranındaki
# nokta (halkaların hangi yönden dolaşılacağını belirlemek için).
#
# DİKKAT — KAYNAK: Şekil Hasenat glifinden gelir (doğrulanabilir). Başlangıç
# noktası, yön ve sıra ise projede kaynağı OLMAYAN, genel nesih el yazısı
# alışkanlığına göre seçilmiş ÖNERİLERDİR (gövde önce, noktalar sonra; çoğu
# hareket yukarıdan/sağdan başlar). Uygulama bunları "bir yol" olarak gösterir
# ve değerlendirme yön/sıra bağımsızdır.
RECIPES = {
    1: [[(0.49, 0.12), (0.513, 0.868)]],
    2: [[(0.837, 0.231), (0.184, 0.307)]],
    3: [[(0.837, 0.355), (0.184, 0.434)]],
    4: [[(0.837, 0.411), (0.184, 0.49)]],
    5: [[(0.79, 0.15), (0.805, 0.79)]],
    6: [[(0.79, 0.15), (0.805, 0.79)]],
    7: [[(0.729, 0.303), (0.741, 0.809)]],
    8: [[(0.433, 0.12), (0.226, 0.84)]],
    9: [[(0.46, 0.368), (0.309, 0.853)]],
    10: [[(0.709, 0.12), (0.222, 0.815)]],
    11: [[(0.654, 0.328), (0.289, 0.833)]],
    12: [[(0.848, 0.219), (0.73, 0.266), (0.558, 0.343), (0.192, 0.464)]],
    13: [[(0.811, 0.38), (0.707, 0.417), (0.552, 0.486), (0.224, 0.594)]],
    14: [[(0.583, 0.461), ('e', 0, 0.3), ('e', 0, 0.7), (0.581, 0.459),
          (0.47, 0.394), (0.177, 0.493)]],
    15: [[(0.583, 0.503), ('e', 0, 0.3), ('e', 0, 0.7), (0.581, 0.501),
          (0.47, 0.436), (0.177, 0.535)]],
    16: [[(0.149, 0.786), ('e', 1, 0.3), ('e', 1, 0.7), (0.463, 0.717)],
         [(0.429, 0.129), (0.46, 0.717)]],
    17: [[(0.15, 0.783), ('e', 2, 0.7), ('e', 2, 0.3), (0.463, 0.715)],
         [(0.429, 0.129), (0.46, 0.715)]],
    18: [[(0.505, 0.163), (0.423, 0.361), (0.628, 0.238), (0.423, 0.361),
          (0.741, 0.812)]],
    19: [[(0.496, 0.286), (0.424, 0.449), (0.6, 0.349), (0.424, 0.449),
          (0.69, 0.822)]],
    20: [[(0.828, 0.487), ('e', 1, 0.3), ('e', 1, 0.7), (0.826, 0.487),
          (0.181, 0.518)]],
    21: [[(0.712, 0.477), ('e', 0, 0.3), ('e', 0, 0.7), (0.712, 0.48),
          (0.307, 0.485)]],
    22: [[(0.665, 0.136), (0.257, 0.734)],
         [(0.487, 0.312), (0.319, 0.572)]],
    23: [[(0.628, 0.12), (0.37, 0.573)]],
    24: [[(0.4, 0.241), (0.43, 0.875)]],
    25: [[(0.674, 0.214), (0.299, 0.441)]],
    26: [[(0.672, 0.345), ('e', 1, 0.5), (0.622, 0.203), ('e', 2, 0.5),
          (0.675, 0.341), (0.272, 0.807)]],
    27: [[(0.5, 0.206), (0.511, 0.286), ('e', 0, 0.3), ('e', 0, 0.7),
          (0.517, 0.286)]],
    28: [[(0.779, 0.162), (0.274, 0.271)]],
}


# ---------------------------------------------------------------------------
# Tariflerden model üretimi


def bfs(pts, a, b):
    from collections import deque
    prev = {a: None}
    q = deque([a])
    while q:
        p = q.popleft()
        if p == b:
            break
        for dy, dx in NB:
            r = (p[0] + dy, p[1] + dx)
            if r in pts and r not in prev:
                prev[r] = p
                q.append(r)
    if b not in prev:
        raise SystemExit(f'yol yok: {a} -> {b}')
    path = []
    p = b
    while p is not None:
        path.append(p)
        p = prev[p]
    return path[::-1]


def build_models():
    models = {}
    for i, ch in enumerate(LETTERS):
        lid = i + 1
        mask = render(ch)
        norm, side = normalizer(mask)
        ys_, xs_ = np.nonzero(mask)
        x0, x1, y0, y1 = xs_.min(), xs_.max(), ys_.min(), ys_.max()
        ox = x0 - (side - (x1 - x0 + 1)) / 2
        oy = y0 - (side - (y1 - y0 + 1)) / 2

        def to_px(p):
            return (p[1] * side + oy, p[0] * side + ox)  # (row, col)

        lab = label(mask, connectivity=2)
        regions = sorted(regionprops(lab), key=lambda r: -r.area)
        body = np.zeros_like(mask)
        for r in regions:
            if r.area >= regions[0].area * 0.3:
                body[lab == r.label] = True
        skel = skeletonize(body)
        pts = set(zip(*np.nonzero(skel)))
        raw = [e for e in edges_of(skel) if len(e) >= side * 0.03]
        arr = np.array(sorted(pts))

        def snap(spec):
            if spec[0] == 'e':
                e = raw[spec[1]]
                return e[min(len(e) - 1, int(round(spec[2] * (len(e) - 1))))]
            r, c = to_px(spec)
            k = int(np.argmin((arr[:, 0] - r) ** 2 + (arr[:, 1] - c) ** 2))
            return tuple(arr[k])

        strokes = []
        for recipe in RECIPES[lid]:
            anchors = [snap(s) for s in recipe]
            path = [anchors[0]]
            for a, b in zip(anchors, anchors[1:]):
                path += bfs(pts, a, b)[1:]
            simp = rdp([(c, r) for (r, c) in path], side * 0.004)
            strokes.append({'px': path, 'points': [norm(x, y) for (x, y) in simp]})

        # tarif bütün gövdeyi kapsıyor mu? (iskelet pikselleri, hareketlere yakın)
        stroke_px = np.array([p for s in strokes for p in s['px']])
        near = 0
        for p in arr:
            d = np.min(np.abs(stroke_px - p).max(axis=1))
            if d <= side * 0.03:
                near += 1
        coverage = near / len(arr)
        models[lid] = {'char': ch, 'strokes': strokes, 'coverage': coverage,
                       'side': side, 'ox': ox, 'oy': oy, 'mask': mask}
    return models


def write_dart(models, edges_json):
    lines = [
        '// ÜRETİLDİ — elle düzenleme: tool/harf_ciziyorum/extract_centerlines.py',
        '// Şekil: Hasenat glifinin merkez çizgisi. Başlangıç/yön/sıra: öneri',
        '// (projede kaynağı yok), bkz. docs/OYUNLAR.md "Harf Çiziyorum".',
        '',
        "import 'dart:ui';",
        '',
        "import 'ciz_models.dart';",
        '',
        'const Map<int, LetterTraceModel> kLetterTraceModels = {',
    ]
    for lid, m in models.items():
        dots = edges_json[lid]['dots']
        pen = edges_json[lid]['penWidth']
        lines.append(f"  // {m['char']}")
        lines.append(f'  {lid}: LetterTraceModel(')
        lines.append(f'    letterId: {lid},')
        lines.append(f'    penWidth: {pen},')
        lines.append('    strokes: [')
        for s in m['strokes']:
            pts = ', '.join(f'Offset({x}, {y})' for (x, y) in s['points'])
            lines.append(f'      TraceStroke([{pts}]),')
        lines.append('    ],')
        if dots:
            lines.append('    dots: [')
            for d in dots:
                (x, y) = d['center']
                lines.append(f"      TraceDot(Offset({x}, {y}), {d['size']}),")
            lines.append('    ],')
        lines.append('  ),')
    lines.append('};')
    path = os.path.join(ROOT, 'lib', 'screens', 'oyunlar', 'harf_ciziyorum', 'ciz_models_data.dart')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(lines) + '\n')
    print('yazıldı:', path)


def draw_checks(models, edges_json):
    import math
    for lid, m in models.items():
        side, ox, oy = m['side'], m['ox'], m['oy']
        vis = Image.new('RGB', (CANVAS, CANVAS), 'white')
        vis.paste((205, 205, 205), mask=Image.fromarray((m['mask'] * 255).astype(np.uint8)))
        d = ImageDraw.Draw(vis)
        colors = [(220, 40, 40), (40, 80, 220)]
        for k, s in enumerate(m['strokes']):
            pts = [(x * side + ox, y * side + oy) for (x, y) in s['points']]
            col = colors[k % 2]
            d.line(pts, fill=col, width=5)
            sx, sy = pts[0]
            d.ellipse([sx - 14, sy - 14, sx + 14, sy + 14], fill=(40, 170, 90))
            d.text((sx - 4, sy - 7), str(k + 1), fill='white')
            # oklar
            total = sum(math.dist(a, b) for a, b in zip(pts, pts[1:]))
            acc, target = 0, total * 0.2
            for a, b in zip(pts, pts[1:]):
                seg = math.dist(a, b)
                while seg > 0 and acc + seg >= target:
                    t = (target - acc) / seg
                    px, py = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
                    ang = math.atan2(b[1] - a[1], b[0] - a[0])
                    for da in (2.6, -2.6):
                        d.line([(px, py), (px + 22 * math.cos(ang + da), py + 22 * math.sin(ang + da))], fill=col, width=5)
                    target += total * 0.2
                acc += seg
        for dot in edges_json[lid]['dots']:
            (x, y) = dot['center']
            px, py = x * side + ox, y * side + oy
            d.ellipse([px - 12, py - 12, px + 12, py + 12], outline=(200, 150, 0), width=4)
        d.text((10, 10), f"{lid} kapsama {m['coverage']:.2f}", fill='black')
        vis.save(os.path.join(OUT, f'model_{lid:02d}.png'))


def build():
    with open(os.path.join(OUT, 'edges.json'), encoding='utf-8') as f:
        edges_json = {int(k): v for k, v in json.load(f).items()}
    models = build_models()
    for lid, m in models.items():
        print(lid, m['char'], 'hareket', len(m['strokes']), 'kapsama', round(m['coverage'], 3),
              [len(s['points']) for s in m['strokes']])
    write_dart(models, edges_json)
    draw_checks(models, edges_json)


if __name__ == '__main__':
    main()
    build()

