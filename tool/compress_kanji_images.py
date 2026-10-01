#!/usr/bin/env python3
"""Resizes and compresses kanji memory-technique images to WebP, keeping the
bundled app small without visibly hurting quality - see
assets/kanji_memory/README.md for the naming convention these need to
follow (and for how to actually attach one to a kanji in the data file).

Usage:
    python tool/compress_kanji_images.py <source_dir> [--max-size 600] [--quality 80]

Every image in <source_dir> is resized (if larger than --max-size on its
longest edge) and re-saved as WebP into assets/kanji_memory/, keeping each
file's original base name (so name source files by the kanji's KanjiVG hex
code up front, e.g. 706b.png -> assets/kanji_memory/706b.webp).
"""
import argparse
import sys
from pathlib import Path

from PIL import Image

DEST_DIR = Path(__file__).resolve().parent.parent / "assets" / "kanji_memory"


def compress_one(src: Path, max_size: int, quality: int) -> tuple[int, int]:
    with Image.open(src) as img:
        img = img.convert("RGB") if img.mode in ("P", "CMYK") else img
        width, height = img.size
        longest = max(width, height)
        if longest > max_size:
            scale = max_size / longest
            img = img.resize((round(width * scale), round(height * scale)), Image.LANCZOS)
        dest = DEST_DIR / (src.stem + ".webp")
        img.save(dest, "WEBP", quality=quality, method=6)
        return src.stat().st_size, dest.stat().st_size


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("source_dir", type=Path, help="Folder of raw source images")
    parser.add_argument("--max-size", type=int, default=600, help="Max pixels on the longest edge (default 600)")
    parser.add_argument("--quality", type=int, default=80, help="WebP quality 0-100 (default 80)")
    args = parser.parse_args()

    if not args.source_dir.is_dir():
        print(f"Not a directory: {args.source_dir}", file=sys.stderr)
        sys.exit(1)

    DEST_DIR.mkdir(parents=True, exist_ok=True)
    exts = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tiff"}
    sources = sorted(p for p in args.source_dir.iterdir() if p.suffix.lower() in exts)
    if not sources:
        print(f"No images found in {args.source_dir}")
        return

    total_before = total_after = 0
    for src in sources:
        before, after = compress_one(src, args.max_size, args.quality)
        total_before += before
        total_after += after
        print(f"{src.name}: {before/1024:.1f} KB -> {src.stem}.webp: {after/1024:.1f} KB")

    print(f"\n{len(sources)} image(s) processed.")
    print(f"Total: {total_before/1024:.1f} KB -> {total_after/1024:.1f} KB "
          f"({(1 - total_after/total_before) * 100:.0f}% smaller)" if total_before else "")


if __name__ == "__main__":
    main()
