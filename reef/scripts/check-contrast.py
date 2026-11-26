#!/usr/bin/env python3
"""Check text contrast in design/tokens.json (CLAUDE.md: text at least 4.5:1).

Covers the reference schemes (all four themes) and the Island's fixed roles: every
on-* role against the role it sits on, body text on every surface, and the Island's text
on its black and grays. Generated schemes follow M3's tone recipe (contrast by
construction) and classic palettes are corrected at runtime by schemegen's classic(), so
this guards the values Reef shows by default and the fixed ones it never regenerates.

Exit status 1 if any pair is below its minimum.   python3 reef/scripts/check-contrast.py
"""
import json
import sys
from pathlib import Path

TOKENS = Path(__file__).resolve().parents[2] / "design" / "tokens.json"

TEXT = 4.5
SURFACES = ["surface", "surface-container-lowest", "surface-container-low", "surface-container",
            "surface-container-high", "surface-container-highest"]
ISLAND = ["island", "island-container", "island-container-high"]

PAIRS = [(f"on-{r}", r, TEXT) for r in ["primary", "primary-container", "secondary", "secondary-container",
                                         "tertiary", "tertiary-container", "error", "error-container"]]
PAIRS += [(t, s, TEXT) for t in ["on-surface", "on-surface-variant"] for s in SURFACES]
PAIRS += [("inverse-on-surface", "inverse-surface", TEXT)]
PAIRS += [(t, s, TEXT) for t in ["on-island", "on-island-variant"] for s in ISLAND]
PAIRS += [("on-island-accent", "island-accent", TEXT), ("island-accent", "island", TEXT)]


def lum(hex_):
    h = hex_.lstrip("#")[:6]
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    c = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def ratio(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def main():
    t = json.loads(TOKENS.read_text())
    roles = {tok["name"]: tok["value"] for tok in t["color"]["tokens"]}
    themes = [th["id"] for th in t["color"]["themes"]]
    failures, worst = [], (99, "")
    for theme in themes:
        for fg, bg, minimum in PAIRS:
            a, b = roles[fg], roles[bg]
            a = a[theme] if isinstance(a, dict) else a
            b = b[theme] if isinstance(b, dict) else b
            r = ratio(a, b)
            if r < worst[0]:
                worst = (r, f"{theme}: {fg} on {bg}")
            if r < minimum:
                failures.append(f"{theme}: {fg} {a} on {bg} {b} = {r:.2f} (needs {minimum})")
    print(f"{len(PAIRS) * len(themes)} pairs, lowest {worst[0]:.2f} ({worst[1]})")
    for f in failures:
        print("FAIL", f)
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
