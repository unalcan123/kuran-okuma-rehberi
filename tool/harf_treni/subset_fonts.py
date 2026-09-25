"""Harf Treni (Seviye 4) için Arapça yazı tiplerini hazırlar.

Kaynak: Google Fonts deposu (SIL Open Font License 1.1, "Reserved Font Name"
tanımlı değil):
  https://github.com/google/fonts/raw/main/ofl/notonaskharabic/NotoNaskhArabic%5Bwght%5D.ttf
  https://github.com/google/fonts/raw/main/ofl/notosansarabic/NotoSansArabic%5Bwdth%2Cwght%5D.ttf
Değişken yazı tipi normal kalınlıkta (wght=400, wdth=100) sabitlenir ve
yalnızca Arapça blok (U+0600–06FF) bırakılır; şekillendirme özellikleri
(başta/ortada/sonda biçimler) korunur. Uygulama boyutu küçük kalır.

Kullanım: python tool/harf_treni/subset_fonts.py <naskh.ttf> <sans.ttf>
Gerekenler: pip install fonttools
"""
import os
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'assets', 'fonts')


def build(src, dst, axes):
    font = TTFont(src)
    font = instancer.instantiateVariableFont(font, axes)
    opts = subset.Options()
    opts.layout_features = ['*']
    opts.name_IDs = ['*']
    opts.name_languages = ['*']
    opts.notdef_outline = True
    opts.glyph_names = False
    sub = subset.Subsetter(options=opts)
    sub.populate(unicodes=list(range(0x0600, 0x0700)) + [0x0020, 0x00A0, 0x200C, 0x200D])
    sub.subset(font)
    font.save(dst)
    print(dst, os.path.getsize(dst), 'bayt')


if __name__ == '__main__':
    naskh, sans = sys.argv[1], sys.argv[2]
    build(naskh, os.path.join(OUT, 'NotoNaskhArabic-Arapca.ttf'), {'wght': 400})
    build(sans, os.path.join(OUT, 'NotoSansArabic-Arapca.ttf'), {'wght': 400, 'wdth': 100})
