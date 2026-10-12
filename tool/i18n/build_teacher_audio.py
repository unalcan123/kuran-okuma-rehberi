#!/usr/bin/env python3
"""Sesli öğretmen konuşmalarının ses manifestlerini üretir/günceller.

Kaynak: tool/i18n/teacher_lines.json (kimlik → dil → metin).
Çıktı:  tool/i18n/teacher_audio_<dil>.json (generate_turkish_audio.py biçimi).

Ses sağlayıcısı manifest `defaults`'ındadır (provider, voiceId, model). İleride
izin alınmış başka bir sese (ör. hocamızın izinli klonu) geçmek için yalnızca
`--voice` ile yeniden çalıştırıp üreticiyi `--force` ile çalıştır; uygulama
kodu değişmez. Hocamızın orijinal kayıtları bu sistemin dışındadır.

Kullanım (depo kökünden):
  python tool/i18n/build_teacher_audio.py [--voice <voice_id>]
  python tool/turkish_audio/generate_turkish_audio.py --manifest tool/i18n/teacher_audio_tr.json --all
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LINES = ROOT / "tool/i18n/teacher_lines.json"
LANGUAGES = ["tr", "es", "fr", "en", "nl", "de", "bs"]
DEFAULT_VOICE = "J17lijyP1BHYcM7ld0Rg"  # uygulamanın öteki açıklamalarıyla aynı ses


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--voice", default=None)
    args = parser.parse_args()
    lines = json.loads(LINES.read_text(encoding="utf-8"))["lines"]
    for lang in LANGUAGES:
        path = ROOT / f"tool/i18n/teacher_audio_{lang}.json"
        old = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
        previous = {e["id"]: e for e in old.get("entries", [])}
        defaults = old.get("defaults") or {
            "provider": "elevenlabs",
            "voiceId": DEFAULT_VOICE,
            "model": "eleven_flash_v2_5",
            "outputFormat": "mp3_44100_128",
            "languageCode": lang,
            "voiceSettings": {
                "stability": 0.5,
                "similarity_boost": 0.75,
                "style": 0.0,
                "use_speaker_boost": True,
            },
            "transcode": {"sampleRate": 24000, "bitrate": "40k"},
        }
        if args.voice:
            defaults["voiceId"] = args.voice
        entries = []
        for line_id, texts in lines.items():
            text = texts[lang]
            entry = dict(previous.get(line_id, {}))
            entry.update(
                id=line_id,
                kind="teacher",
                text=text,
                ttsText=text,
                file=f"assets/audio/{lang}/{line_id}.mp3",
                # Konuşmalarda Arapça yok; olsaydı insan onayı gerekirdi.
                needsPronunciationReview=False,
            )
            entry.setdefault("status", "pending")
            entries.append(entry)
        manifest = {
            "schemaVersion": 1,
            "language": lang,
            "about": "Sesli öğretmen (yapay zekâ sesi). Kaynak teacher_lines.json; build_teacher_audio.py üretir.",
            "defaults": defaults,
            "entries": entries,
        }
        with path.open("w", encoding="utf-8", newline="\n") as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print(f"{path.relative_to(ROOT)}: {len(entries)} konuşma")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
