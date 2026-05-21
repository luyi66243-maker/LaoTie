#!/usr/bin/env python3
"""
Batch generate natural-sounding audio for LaoTie app using Edge-TTS.

Voices:
  - zh-CN-liaoning-XiaobeiNeural  (辽宁方言女声, 东北腔)  → 东北话音频
  - zh-CN-XiaoxiaoNeural          (标准普通话女声, 温暖)  → 普通话音频

Output: m4a files (AAC-LC, 22050Hz, mono) matching the app's existing format.
"""

import asyncio
import json
import os
import subprocess
import sys
from pathlib import Path

# --- Configuration ---
DONGBEI_VOICE = "zh-CN-liaoning-XiaobeiNeural"
STANDARD_VOICE = "zh-CN-XiaoxiaoNeural"

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SEED_DATA = PROJECT_ROOT / "LaoTie" / "Resources" / "SeedData"
AUDIO_VOCAB = PROJECT_ROOT / "LaoTie" / "Resources" / "Audio" / "vocabulary"
AUDIO_STD = PROJECT_ROOT / "LaoTie" / "Resources" / "Audio" / "standard"
TMP_DIR = Path("/tmp/laotie_tts")


async def tts_generate(text: str, voice: str, output_mp3: Path):
    """Generate mp3 using edge-tts."""
    import edge_tts
    communicate = edge_tts.Communicate(text, voice)
    await communicate.save(str(output_mp3))


def mp3_to_m4a(mp3_path: Path, m4a_path: Path):
    """Convert mp3 to m4a (AAC-LC, 22050Hz, mono) using ffmpeg."""
    subprocess.run(
        [
            "ffmpeg", "-y", "-i", str(mp3_path),
            "-c:a", "aac", "-b:a", "64k",
            "-ar", "22050", "-ac", "1",
            str(m4a_path),
        ],
        capture_output=True,
        check=True,
    )


async def generate_one(text: str, voice: str, filename: str, out_dir: Path):
    """Generate one audio file: TTS → mp3 → m4a."""
    mp3_path = TMP_DIR / f"{filename}.mp3"
    m4a_path = out_dir / f"{filename}.m4a"

    if m4a_path.exists() and m4a_path.stat().st_size > 500:
        return False  # skip if already exists and non-trivial

    try:
        await tts_generate(text, voice, mp3_path)
        mp3_to_m4a(mp3_path, m4a_path)
        return True
    except Exception as e:
        print(f"  [ERROR] {filename}: {e}", file=sys.stderr)
        return False


async def process_vocabularies():
    """Generate audio for all 100 vocabulary words."""
    vocab_path = SEED_DATA / "vocabularies.json"
    with open(vocab_path, "r", encoding="utf-8") as f:
        vocabs = json.load(f)

    print(f"\n{'='*60}")
    print(f"  Generating vocabulary audio ({len(vocabs)} words)")
    print(f"{'='*60}")

    generated = 0
    skipped = 0

    for i, v in enumerate(vocabs):
        vid = v["id"]  # e.g. "v001"
        dongbei_word = v["dongbeiWord"]
        standard_word = v["standardWord"]
        example = v.get("exampleSentence", "")

        # --- Dongbei pronunciation ---
        # Use example sentence for richer audio, fallback to word alone
        dongbei_text = example if example else dongbei_word
        result = await generate_one(dongbei_text, DONGBEI_VOICE, vid, AUDIO_VOCAB)
        if result:
            generated += 1
            print(f"  [{i+1:3d}/{len(vocabs)}] {vid} 东北: {dongbei_text[:30]}...")
        else:
            skipped += 1

        # --- Standard pronunciation ---
        std_text = v.get("exampleTranslation", "") or standard_word
        s_vid = f"s_{vid}"
        result = await generate_one(std_text, STANDARD_VOICE, s_vid, AUDIO_STD)
        if result:
            generated += 1
            print(f"  [{i+1:3d}/{len(vocabs)}] {s_vid} 标准: {std_text[:30]}...")
        else:
            skipped += 1

    print(f"\n  Vocabulary done: {generated} generated, {skipped} skipped")
    return generated


async def process_dialogues():
    """Generate audio for all dialogue lines."""
    dial_path = SEED_DATA / "dialogues.json"
    with open(dial_path, "r", encoding="utf-8") as f:
        dialogues = json.load(f)

    total_lines = sum(len(d["lines"]) for d in dialogues)
    print(f"\n{'='*60}")
    print(f"  Generating dialogue audio ({total_lines} lines)")
    print(f"{'='*60}")

    generated = 0
    skipped = 0
    count = 0

    for d in dialogues:
        for line in d["lines"]:
            count += 1
            lid = line["id"]  # e.g. "d001_l1"
            dongbei_text = line["dongbeiText"]
            standard_text = line["standardText"]

            # --- Dongbei ---
            result = await generate_one(dongbei_text, DONGBEI_VOICE, lid, AUDIO_VOCAB)
            if result:
                generated += 1
                print(f"  [{count:3d}/{total_lines}] {lid} 东北: {dongbei_text[:30]}...")
            else:
                skipped += 1

            # --- Standard ---
            s_lid = f"s_{lid}"
            result = await generate_one(standard_text, STANDARD_VOICE, s_lid, AUDIO_STD)
            if result:
                generated += 1
                print(f"  [{count:3d}/{total_lines}] {s_lid} 标准: {standard_text[:30]}...")
            else:
                skipped += 1

    print(f"\n  Dialogues done: {generated} generated, {skipped} skipped")
    return generated


async def main():
    # Ensure directories exist
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    AUDIO_VOCAB.mkdir(parents=True, exist_ok=True)
    AUDIO_STD.mkdir(parents=True, exist_ok=True)

    force = "--force" in sys.argv
    if force:
        print("Force mode: regenerating ALL audio files")
        # Remove existing files to force regeneration
        for f in AUDIO_VOCAB.glob("*.m4a"):
            f.unlink()
        for f in AUDIO_STD.glob("*.m4a"):
            f.unlink()

    v_count = await process_vocabularies()
    d_count = await process_dialogues()

    # Clean up tmp
    for f in TMP_DIR.glob("*.mp3"):
        f.unlink()

    total = v_count + d_count
    print(f"\n{'='*60}")
    print(f"  ALL DONE: {total} audio files generated")
    print(f"  Vocabulary dir: {AUDIO_VOCAB}")
    print(f"  Standard dir:   {AUDIO_STD}")
    print(f"{'='*60}")


if __name__ == "__main__":
    asyncio.run(main())
