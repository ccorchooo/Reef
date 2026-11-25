#!/usr/bin/env python3
"""Generate reef/assets/emoji.json (the Tools tab's emoji picker) from Unicode's emoji-test.txt.

Usage: python3 reef/scripts/gen-emoji.py [path/to/emoji-test.txt]
Default input: oh-my-zsh's copy (/usr/share/oh-my-zsh/plugins/emoji/emoji-data.txt).
Keeps fully-qualified emoji without skin-tone variants, in CLDR order, as
[{"e": "😀", "n": "grinning face", "g": "Smileys & Emotion"}, …].
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = Path(sys.argv[1] if len(sys.argv) > 1 else "/usr/share/oh-my-zsh/plugins/emoji/emoji-data.txt")
OUT = ROOT / "reef" / "assets" / "emoji.json"
TONES = {0x1F3FB, 0x1F3FC, 0x1F3FD, 0x1F3FE, 0x1F3FF}

out, group = [], ""
for line in SRC.read_text(encoding="utf-8").splitlines():
    if line.startswith("# group:"):
        group = line.split(":", 1)[1].strip()
        continue
    m = re.match(r"([0-9A-F ]+);\s*fully-qualified\s*#\s*(\S+)\s+(?:E\d+\.\d+\s+)?(.+)", line)
    if not m or group == "Component":
        continue
    cps = [int(c, 16) for c in m.group(1).split()]
    if TONES & set(cps):
        continue
    out.append({"e": "".join(map(chr, cps)), "n": m.group(3).strip(), "g": group})

OUT.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
print(f"wrote {OUT.relative_to(ROOT)} ({len(out)} emoji)")
