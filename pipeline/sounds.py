"""The app's sound effects, synthesized (no recording, no licence): soft and short.

    py pipeline/sounds.py   -> app/assets/sounds/{tap,swipe,reveal}.wav
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 32000
OUT = Path(__file__).resolve().parent.parent / "app" / "assets" / "sounds"


def write(name, samples):
    peak = max(abs(s) for s in samples)
    assert 0 < peak <= 1, (name, peak)  # self-check: never clips
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", round(s * 32767)) for s in samples))


def tone(freq, seconds, decay, amp):
    """A sine with a 5 ms fade-in and an exponential decay (a struck, wooden or glassy note)."""
    return [amp * min(1, i / (0.005 * RATE)) * math.exp(-i / (decay * RATE))
            * math.sin(2 * math.pi * freq * i / RATE) for i in range(int(seconds * RATE))]


def mix(*tracks, offsets=None):
    offsets = offsets or [0] * len(tracks)
    n = max(int(o * RATE) + len(t) for o, t in zip(offsets, tracks))
    out = [0.0] * n
    for o, t in zip(offsets, tracks):
        for i, s in enumerate(t):
            out[int(o * RATE) + i] += s
    return out


def tap():
    """A quiet wooden tick: a low note and a faint overtone, gone in 60 ms."""
    return mix(tone(520, 0.08, 0.012, 0.22), tone(1560, 0.08, 0.006, 0.06))


def swipe():
    """A faint paper swish: low-passed noise under a soft swell, 220 ms."""
    rnd = random.Random(1)
    n, y, out = int(0.22 * RATE), 0.0, []
    for i in range(n):
        y += 0.12 * (rnd.uniform(-1, 1) - y)  # one-pole low-pass
        out.append(0.5 * y * math.sin(math.pi * i / n) ** 2)
    return out


def reveal():
    """A calm two-note chime (C6 then G6) with a soft octave partial, ringing out in 0.9 s."""
    def bell(f):
        return mix(tone(f, 0.75, 0.22, 0.16), tone(2 * f, 0.75, 0.1, 0.04))
    return mix(bell(1046.5), bell(1568.0), offsets=[0, 0.12])


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, make in [("tap", tap), ("swipe", swipe), ("reveal", reveal)]:
        write(name, make())
        print(name, (OUT / f"{name}.wav").stat().st_size, "bytes")
