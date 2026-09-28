"""Türkçe Ses Kontrol ekranının verisini manifest'ten yazar.

    python tool/turkish_audio/export_qc_data.py

manifest.json'daki `generated` kayıtları (dosyası olan sesler) PDF sırasıyla
`lib/debug/turkish_audio_qc_data.dart`'a yazar. Ses üretmez, API'ye bağlanmaz.
`test/turkish_audio_qc_test.dart` dosyanın manifest'le aynı olduğunu denetler;
ses üretilince ya da metin değişince bu betiği yeniden çalıştır.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "tool" / "turkish_audio" / "manifest.json"
OUT = ROOT / "lib" / "debug" / "turkish_audio_qc_data.dart"


def dart_string(value: str | None) -> str:
    if value is None:
        return "null"
    escaped = (
        value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\r", "\\r")
        .replace("\n", "\\n")
    )
    return f"'{escaped}'"


def main() -> None:
    entries = json.loads(MANIFEST.read_text(encoding="utf-8"))["entries"]
    order = {e["id"]: i for i, e in enumerate(entries)}
    generated = sorted(
        (e for e in entries if e.get("status") == "generated"),
        key=lambda e: (e["pdfPage"], order[e["id"]]),
    )
    lines = [
        "// Üretildi: python tool/turkish_audio/export_qc_data.py — elle düzenleme.",
        "// Kaynak: tool/turkish_audio/manifest.json (status: generated).",
        "",
        "import 'turkish_audio_qc.dart';",
        "",
        "/// Üretilmiş Türkçe seslerin hepsi, PDF sırasıyla.",
        "const List<TrAudioQcEntry> kTrAudioQcEntries = [",
    ]
    for e in generated:
        lines += [
            "  TrAudioQcEntry(",
            f"    id: {dart_string(e['id'])},",
            f"    pdfPage: {e['pdfPage']},",
            f"    heading: {'true' if e['kind'] == 'heading' else 'false'},",
            f"    text: {dart_string(e['text'])},",
            f"    ttsText: {dart_string(e.get('ttsText'))},",
            "  ),",
        ]
    lines += ["];", ""]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"{len(generated)} entries -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
