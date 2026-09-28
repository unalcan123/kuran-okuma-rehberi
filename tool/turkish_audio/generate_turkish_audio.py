#!/usr/bin/env python3
"""Kitap sayfalarındaki Türkçe açıklama seslerini ElevenLabs ile BİR KEZ üretir.

Uygulama ElevenLabs'e hiç bağlanmaz: sesler assets/audio/tr/ altına mp3 olarak
yazılır ve uygulamayla birlikte gelir. Metinler manifest.json'dadır (uygulamada
gösterilen PDF metni; test/turkish_audio_test.dart ikisinin aynı olduğunu denetler).

Ses: --voice, yoksa ELEVENLABS_VOICE_ID ortam değişkeni, yoksa manifest defaults.voiceId.

API anahtarı:
  ELEVENLABS_API_KEY ortam değişkeni ya da depo kökündeki .env dosyası
  (".env" .gitignore'da). Anahtar hiçbir yere yazılmaz, hiçbir çıktıda görünmez.

Kullanım (depo kökünden):
  python tool/turkish_audio/generate_turkish_audio.py --dry-run
  python tool/turkish_audio/generate_turkish_audio.py --all --voice <voice_id>
  python tool/turkish_audio/generate_turkish_audio.py --id s054_01 --voice <voice_id>
  python tool/turkish_audio/generate_turkish_audio.py --id s054_01 --force
  python tool/turkish_audio/generate_turkish_audio.py --id s050_01 --include-review

Kurallar:
  * Bir kayıt, dosyası varsa ve aynı metin (textHash) + aynı ses (voiceId) +
    aynı model ile üretilmişse atlanır; --force yeniden üretir.
  * needsPronunciationReview=true olan kayıtlar (Arapça harf/kelime içerenler)
    --include-review verilmedikçe üretilmez — --id ile tek tek de olsa.
  * ttsText doluysa ElevenLabs'e o gönderilir (ör. Arapça yerine okunuşu);
    ekranda yine text görünür.
  * ffmpeg varsa çıktı defaults.transcode ayarına (mono, küçük mp3) dönüştürülür;
    yoksa --no-transcode verilmeli. Ses ekleyince `flutter test` kSoundCacheVersion
    için yeni değeri söyler.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = Path(__file__).resolve().parent / "manifest.json"
API_URL = "https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format={fmt}"
# audio_assets_test: bir kayıt 250 KB'tan küçük olmalı (web'de indirme).
MAX_BYTES = 240 * 1024


def load_manifest(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def save_manifest(path: Path, manifest: dict) -> None:
    tmp = path.with_suffix(".json.tmp")
    with tmp.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
        f.write("\n")
    tmp.replace(path)


def spoken(entry: dict) -> str:
    return entry.get("ttsText") or entry["text"]


def text_hash(text: str) -> str:
    return "sha256:" + hashlib.sha256(text.encode("utf-8")).hexdigest()


def api_key() -> str | None:
    key = os.environ.get("ELEVENLABS_API_KEY")
    if key:
        return key.strip()
    # Windows: a user variable set with
    # [Environment]::SetEnvironmentVariable('ELEVENLABS_API_KEY', '…', 'User')
    # is in the registry even for programs started before it was set.
    if sys.platform == "win32":
        import winreg

        try:
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as reg:
                value, _ = winreg.QueryValueEx(reg, "ELEVENLABS_API_KEY")
                if value:
                    return str(value).strip()
        except OSError:
            pass
    env = ROOT / ".env"
    if env.is_file():
        for line in env.read_text(encoding="utf-8").splitlines():
            name, sep, value = line.partition("=")
            if sep and name.strip() == "ELEVENLABS_API_KEY":
                return value.strip().strip('"').strip("'")
    return None


def status(entry: dict, voice: str | None, model: str) -> str:
    """up-to-date | changed | missing"""
    target = ROOT / entry["file"]
    if not target.is_file():
        return "missing"
    same = (
        entry.get("textHash") == text_hash(spoken(entry))
        and entry.get("voiceId") == voice
        and entry.get("model") == model
    )
    return "up-to-date" if same else "changed"


def synthesize(key: str, voice: str, model: str, defaults: dict, text: str) -> bytes:
    body = {
        "text": text,
        "model_id": model,
        "voice_settings": defaults.get("voiceSettings") or {},
    }
    if defaults.get("languageCode"):
        body["language_code"] = defaults["languageCode"]
    request = urllib.request.Request(
        API_URL.format(voice=voice, fmt=defaults.get("outputFormat", "mp3_44100_128")),
        data=json.dumps(body).encode("utf-8"),
        headers={
            "xi-api-key": key,
            "Content-Type": "application/json",
            "Accept": "audio/mpeg",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            return response.read()
    except urllib.error.HTTPError as error:
        # The error body is ElevenLabs' message; the key is never part of it.
        detail = error.read().decode("utf-8", "replace")[:300]
        raise RuntimeError(f"ElevenLabs HTTP {error.code}: {detail}") from None
    except urllib.error.URLError as error:
        raise RuntimeError(f"ElevenLabs'e ulaşılamadı: {error.reason}") from None


def transcode(raw: bytes, settings: dict) -> bytes:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("ffmpeg bulunamadı (kur ya da --no-transcode ver)")
    with tempfile.TemporaryDirectory() as tmp:
        src, dst = Path(tmp, "in.mp3"), Path(tmp, "out.mp3")
        src.write_bytes(raw)
        subprocess.run(
            [
                ffmpeg, "-y", "-loglevel", "error", "-i", str(src),
                "-ac", "1", "-ar", str(settings.get("sampleRate", 24000)),
                "-c:a", "libmp3lame", "-b:a", str(settings.get("bitrate", "40k")),
                "-map_metadata", "-1", str(dst),
            ],
            check=True,
        )
        return dst.read_bytes()


def main() -> int:
    # Turkish text on a Windows console (cp1252) would otherwise crash print().
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(
        description="Türkçe açıklama seslerini ElevenLabs ile üretir (bir kez).",
    )
    pick = parser.add_argument_group("hangi kayıtlar")
    pick.add_argument("--all", action="store_true", help="eksik/değişmiş bütün kayıtlar")
    pick.add_argument("--id", action="append", default=[], metavar="ID", help="tek kayıt (tekrarlanabilir)")
    parser.add_argument("--dry-run", action="store_true", help="API çağırmadan ne yapılacağını göster")
    parser.add_argument("--force", action="store_true", help="güncel olsa da yeniden üret")
    parser.add_argument("--include-review", action="store_true", help="needsPronunciationReview kayıtlarını da üret")
    parser.add_argument("--voice", help="ElevenLabs voice id (yoksa ELEVENLABS_VOICE_ID, sonra manifest defaults.voiceId)")
    parser.add_argument("--model", help="model id (yoksa manifest defaults.model)")
    parser.add_argument("--no-transcode", action="store_true", help="ElevenLabs çıktısını olduğu gibi yaz")
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    args = parser.parse_args()

    if not (args.all or args.id or args.dry_run):
        parser.error("--all, --id veya --dry-run ver")

    manifest = load_manifest(args.manifest)
    defaults = manifest.get("defaults", {})
    voice = args.voice or os.environ.get("ELEVENLABS_VOICE_ID") or defaults.get("voiceId")
    model = args.model or defaults.get("model") or "eleven_multilingual_v2"
    entries = manifest["entries"]
    by_id = {e["id"]: e for e in entries}

    unknown = [i for i in args.id if i not in by_id]
    if unknown:
        print("Manifest'te olmayan id: " + ", ".join(unknown), file=sys.stderr)
        return 2
    chosen = [by_id[i] for i in args.id] if args.id else entries

    todo, skipped = [], {"up-to-date": 0, "review": 0}
    for entry in chosen:
        state = status(entry, voice, model)
        if entry.get("needsPronunciationReview") and not args.include_review:
            skipped["review"] += 1
            if args.id:
                print(f"  {entry['id']}: telaffuz incelemesi bekliyor — --include-review olmadan üretilmez")
            continue
        if state == "up-to-date" and not args.force:
            skipped["up-to-date"] += 1
            continue
        todo.append((entry, state))

    stray = sorted(
        p.name for p in (ROOT / "assets/audio/tr").glob("*.mp3")
        if p.stem not in by_id
    )
    print(
        f"Manifest: {len(entries)} kayıt · seçilen {len(chosen)} · üretilecek {len(todo)} · "
        f"güncel {skipped['up-to-date']} · inceleme bekleyen (atlandı) {skipped['review']}"
    )
    # The voice id is not printed (keeps it out of terminals/logs).
    print(f"Ses: {'ayarlı' if voice else '— seçilmedi —'} · model: {model} · biçim: {defaults.get('outputFormat')}")
    if stray:
        print("Uyarı: manifest'te olmayan dosyalar: " + ", ".join(stray))

    if args.dry_run:
        for entry, state in todo:
            mark = " [inceleme]" if entry.get("needsPronunciationReview") else ""
            print(f"  {entry['id']:<16} {state:<9}{mark} {spoken(entry)[:70]}")
        return 0
    if not todo:
        return 0
    if not voice:
        print("Ses seçilmedi: --voice <voice_id> ver ya da manifest defaults.voiceId doldur.", file=sys.stderr)
        return 2
    key = api_key()
    if not key:
        print("ELEVENLABS_API_KEY yok (ortam değişkeni ya da .env).", file=sys.stderr)
        return 2

    # generation status of every record: generated | pending | pendingReview | failed
    for entry in entries:
        if status(entry, voice, model) == "up-to-date":
            entry["status"] = "generated"
        elif entry.get("status") != "failed":
            entry["status"] = "pendingReview" if entry.get("needsPronunciationReview") else "pending"
    save_manifest(args.manifest, manifest)

    failures = 0
    for entry, state in todo:
        text = spoken(entry)
        try:
            audio = synthesize(key, voice, model, defaults, text)
            if not args.no_transcode:
                audio = transcode(audio, defaults.get("transcode") or {})
        except (RuntimeError, subprocess.CalledProcessError) as error:
            failures += 1
            print(f"  {entry['id']}: HATA — {error}", file=sys.stderr)
            entry["status"] = "failed"
            save_manifest(args.manifest, manifest)
            continue
        target = ROOT / entry["file"]
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(audio)
        entry.update(voiceId=voice, model=model, textHash=text_hash(text), status="generated")
        save_manifest(args.manifest, manifest)  # progress survives a stop
        size = len(audio) // 1024
        warn = "  (!) 240 KB'tan büyük" if len(audio) > MAX_BYTES else ""
        print(f"  {entry['id']}: yazıldı ({state}, {size} KB){warn}")

    print("Bitti. Şimdi `flutter test` çalıştır; kSoundCacheVersion için yeni değeri söyler.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
