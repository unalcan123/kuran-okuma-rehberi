#!/usr/bin/env python3
"""Ders metni çevirilerini lib/l10n/strings/content_strings.g.dart'a yazar.

Kaynak: tool/i18n/content_units.json (sıra ve Türkçe metin) ve
tool/i18n/content_<dil>.json (es, fr, de, en, bs). Hollandaca ayrı:
build_nl_strings.py.

Kullanım (depo kökünden): python tool/i18n/build_content_strings.py
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LANGS = ["es", "fr", "de", "en", "bs"]
TARGET = ROOT / "lib/l10n/strings/content_strings.g.dart"


def dart(text: str) -> str:
    return json.dumps(text, ensure_ascii=False).replace("$", "\\$")


def main() -> int:
    units = json.loads((ROOT / "tool/i18n/content_units.json").read_text(encoding="utf-8"))
    tables = {
        lang: json.loads((ROOT / f"tool/i18n/content_{lang}.json").read_text(encoding="utf-8"))
        for lang in LANGS
    }
    out = [
        "// Generated from tool/i18n/content_<language>.json",
        "const Map<String, List<String>> kContentStrings = {",
    ]
    rows = 0
    seen = set()
    for unit in units:
        source = unit["source"]
        if source in seen:
            continue
        seen.add(source)
        values = [tables[lang].get(source, "") for lang in LANGS]
        if not any(values):
            continue
        rows += 1
        one = f"  {dart(source)}: [{', '.join(dart(v) for v in values)}],"
        if len(one) <= 80:
            out.append(one)
        else:
            out.append(f"  {dart(source)}: [")
            out.extend(f"    {dart(v)}," for v in values)
            out.append("  ],")
    out.append("};")
    TARGET.write_text("\n".join(out) + "\n", encoding="utf-8", newline="\n")
    print(f"{TARGET.relative_to(ROOT)}: {rows} satır")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
