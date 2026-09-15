"""Original Spirit Nexus procedural score. Pure stdlib; no sampled recordings.
Run from repository root. 22050 Hz mono PCM16; music lengths are exact bars.
"""
import math
import wave
from pathlib import Path
RATE = 22050
OUT = Path(__file__).resolve().parents[2] / 'assets/audio/campaign'
OUT.mkdir(parents=True, exist_ok=True)

def render(name, length, sample):
    import array
    pcm = array.array('h', (int(max(-.85, min(.85, sample(i / RATE))) * 32767) for i in range(round(length * RATE))))
    import sys
    if sys.byteorder != 'little':
        pcm.byteswap()
    with wave.open(str(OUT / (name + '.wav')), 'wb') as f:
        f.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        f.writeframes(pcm.tobytes())

def tone(freq, t):
    return math.sin(math.tau * freq * t) + .22 * math.sin(math.tau * freq * 2 * t)

for name, beat, base, notes in [
    ('menu', .625, 196, [0, 7, 12, 14, 7, 4, 2, 7, 0, 4, 9, 7, 14, 12, 7, 2]),
    ('battle', .4, 220, [0, 7, 3, 10, 12, 7, 15, 10, 0, 5, 12, 7, 10, 3, 7, 5]),
    ('boss', .3125, 164.8138, [0, 1, 7, 12, 3, 7, 13, 10, 0, 7, 6, 12, 10, 7, 3, 1]),
]:
    def music(t, beat=beat, base=base, notes=notes):
        step = int(t / beat) % len(notes)
        p = t % beat
        env = (1 - math.exp(-p * 150)) * math.exp(-p * 6 / beat)
        melody = .22 * env * tone(base * 2 ** (notes[step] / 12), p)
        bass = .095 * math.sin(math.tau * base / 2 * p) * math.sin(math.pi * p / beat) ** 2
        return melody + bass
    render(name, beat * 32, music)
for name, freq, length, rise in [('shot', 880, .09, -500), ('hit', 130, .12, -70), ('kill', 520, .13, 220), ('level', 660, .65, 400), ('boss', 110, 1, 90), ('win', 523, 1.4, 260), ('lose', 220, 1.2, -120), ('ui', 740, .075, 70)]:
    if name == 'boss':
        name = 'boss_cue'
    def effect(t, freq=freq, length=length, rise=rise):
        env = math.sin(math.pi * t / length) ** 2 * math.exp(-2 * t / length)
        return .32 * env * math.sin(math.tau * (freq * t + rise * t * t / (2 * length)))
    render(name, length, effect)
print('SPIRIT_NEXUS_AUDIO_GENERATED')
