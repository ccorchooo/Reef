#!/usr/bin/env python3
"""The Reef mark as terminal text, for fastfetch (config/fastfetch/reef.txt).

Renders design/logo/reef-mark-mono.svg with rsvg-convert and samples it into half-block
characters (two pixels per cell, so the ring stays round in a 1:2 cell). The text uses
fastfetch's $1 color, so the mark takes one color, as DESIGN.md asks.

    python3 reef/scripts/gen-logo-text.py [columns]     (needs rsvg-convert and Pillow)
"""
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SVG = ROOT / "design/logo/reef-mark-mono.svg"
OUT = ROOT / "config/fastfetch/reef.txt"


def main():
    cols = int(sys.argv[1]) if len(sys.argv) > 1 else 20
    with tempfile.TemporaryDirectory() as tmp:
        png = Path(tmp) / "mark.png"
        size = cols * 8
        subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), "-o", str(png), str(SVG)], check=True)
        img = Image.open(png).convert("RGBA")
    # Coverage per pixel of a cols × cols grid (alpha averaged over each block).
    small = img.getchannel("A").resize((cols, cols), Image.Resampling.BOX)
    on = [[small.getpixel((x, y)) >= 110 for x in range(cols)] for y in range(cols)]
    rows = []
    for y in range(0, cols, 2):
        top, bottom = on[y], on[y + 1] if y + 1 < cols else [False] * cols
        rows.append("".join("█" if t and b else "▀" if t else "▄" if b else " " for t, b in zip(top, bottom)).rstrip())
    while rows and not rows[0].strip():
        rows.pop(0)
    while rows and not rows[-1].strip():
        rows.pop()
    width = max(len(r) for r in rows)
    OUT.write_text("".join("$1" + r.ljust(width) + "\n" for r in rows))
    print(f"wrote {OUT.relative_to(ROOT)} ({width}×{len(rows)})")
    print("\n".join(r for r in rows))


if __name__ == "__main__":
    main()
