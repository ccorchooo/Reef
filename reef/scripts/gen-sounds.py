#!/usr/bin/env python3
"""Synthesize Reef's UI sounds from design/tokens.json → reef/assets/sounds/<name>.wav.

DESIGN.md § 8: very subtle, short (under 150 ms), soft. Each note is a sine with a few
soft overtones, a short linear attack and an exponential decay that reaches silence at
the note's end; `to` glides the pitch. Standard library only.

Run after changing the `sound` group in tokens.json:  python3 reef/scripts/gen-sounds.py
"""
import json
import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TOKENS = ROOT / "design" / "tokens.json"
OUT = ROOT / "reef" / "assets" / "sounds"


def render(sound: dict, cfg: dict) -> list[float]:
    rate = cfg["rate"]
    attack = cfg["attack"] / 1000
    overtones = cfg["overtones"]
    end = max(n["at"] + n["dur"] for n in sound["notes"]) / 1000
    if end > 0.15:
        raise SystemExit(f"{sound['name']}: {end * 1000:.0f} ms is longer than 150 ms")
    out = [0.0] * (int(end * rate) + 1)
    for n in sound["notes"]:
        start, dur = n["at"] / 1000, n["dur"] / 1000
        f0, f1 = n["hz"], n.get("to", n["hz"])
        phase = 0.0
        for i in range(int(dur * rate)):
            t = i / rate
            # Exponential pitch glide, so a glide sounds even across octaves.
            f = f0 * (f1 / f0) ** (t / dur)
            phase += 2 * math.pi * f / rate
            # Decay to about -60 dB at the end, then a tiny linear tail to exact zero.
            env = min(1.0, t / attack) * math.exp(-6.9 * t / dur) * (1 - t / dur)
            s = sum(a * math.sin(phase * (k + 1)) for k, a in enumerate(overtones))
            out[int(start * rate) + i] += s * env
    return out


def main():
    tokens = json.loads(TOKENS.read_text())
    cfg = tokens["sound"]
    OUT.mkdir(parents=True, exist_ok=True)
    for sound in cfg["sounds"]:
        samples = render(sound, cfg)
        peak = max(abs(s) for s in samples) or 1
        scale = cfg["peak"] / peak
        path = OUT / f"{sound['name']}.wav"
        with wave.open(str(path), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(cfg["rate"])
            w.writeframes(b"".join(struct.pack("<h", round(s * scale * 32767)) for s in samples))
        print(f"{path.relative_to(ROOT)}  {len(samples) / cfg['rate'] * 1000:.0f} ms")


if __name__ == "__main__":
    main()
