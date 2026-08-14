# Web — Audio Module Reference

**Last verified:** 2026-08-06
**Knowledge Gap:** none major — but the autoplay gesture requirement is the most commonly missed constraint on the platform

---

## The One Rule That Breaks Every Project

**Audio cannot start without a user gesture.** Browsers suspend the
`AudioContext` until the user interacts with the page. There is no workaround,
no flag, and no permission prompt.

Every web game needs an explicit start interaction.

```ts
const ctx = new AudioContext();   // starts in state 'suspended'

// Must run inside a real user-gesture handler
startButton.addEventListener('click', async () => {
  await ctx.resume();             // now 'running'
  startGame();
});
```

Design implication: a "Click to Play" screen is not a stylistic choice, it is a
platform requirement. Fold it into the title screen rather than bolting it on.

Also re-check `ctx.state` after tab focus returns — some browsers re-suspend.

---

## Web Audio Graph

```
AudioBufferSourceNode → GainNode (per-category) → GainNode (master) → destination
```

Route every sound through a category bus so mixing is possible:

```ts
const master = ctx.createGain();
master.connect(ctx.destination);

const sfxBus = ctx.createGain();
const musicBus = ctx.createGain();
sfxBus.connect(master);
musicBus.connect(master);
```

### Volume changes must be ramped
```ts
// ❌ Audible click
gain.gain.value = 0.5;

// ✅ Smooth
gain.gain.setTargetAtTime(0.5, ctx.currentTime, 0.01);
```
Setting `.value` directly produces a discontinuity in the waveform, which is
heard as a click or pop.

### Sources are single-use
`AudioBufferSourceNode` cannot be replayed. Create a new one per playback — this
is by design and is cheap. Reuse the decoded `AudioBuffer`, not the node.

```ts
function play(buffer: AudioBuffer, bus: GainNode): void {
  const src = ctx.createBufferSource();
  src.buffer = buffer;              // buffer is reused
  src.connect(bus);
  src.start();                      // node is disposable
}
```

---

## Formats

| Format | Use |
|--------|-----|
| **Opus in WebM** | Primary — best quality per byte |
| **AAC in MP4** | Fallback for older Safari |
| WAV | Never ship — uncompressed, enormous |

Audio is often the largest asset category in a 2D game. Compress aggressively:
music at 96–128 kbps stereo, SFX at 64–96 kbps mono is usually transparent in
gameplay context.

### Audio sprites
Concatenate short SFX into one file and play by offset. Cuts request count and
decode overhead substantially.

```ts
src.start(0, sprite.offset, sprite.duration);
```

---

## Timing

**Never schedule audio with `setTimeout`.** Its resolution is tens of
milliseconds and it is throttled in background tabs.

```ts
// ✅ Sample-accurate scheduling on the audio clock
src.start(ctx.currentTime + 0.5);
```

`ctx.currentTime` is the audio clock. For rhythm games and beat-synced music,
drive scheduling from it, not from `requestAnimationFrame`.

Schedule ahead in a lookahead window (typically 100ms) rather than one note at a
time — the audio thread must never wait on the main thread.

---

## Mobile Constraints

- iOS caps the number of simultaneous `AudioContext` instances — use exactly one for the whole game
- Background tabs suspend audio; handle `visibilitychange` and pause music explicitly
- The silent/ringer switch on iOS affects Web Audio in some configurations — do not rely on audio for critical feedback
- Decoding is expensive on low-end phones; decode during loading, never mid-gameplay

---

## Howler.js — When to Use It

`howler` handles the autoplay unlock, audio sprites, format fallback, and pooling
that are tedious to write by hand. Worth the ~20KB for most projects.

Prefer raw Web Audio when: audio needs are simple, or the project needs
sample-accurate scheduling that a wrapper abstracts away.

See `../PLUGINS.md`.

---

## Common Errors

| Symptom | Cause |
|---------|-------|
| No audio at all, no error | `AudioContext` never resumed after a gesture |
| Clicks and pops on volume change | Setting `gain.value` directly instead of ramping |
| "Cannot call start more than once" | Reusing an `AudioBufferSourceNode` |
| Music drifts out of sync | Scheduling with `setTimeout` instead of `ctx.currentTime` |
| Audio stops after tab switch | Not handling `visibilitychange` |
| Huge download | Shipping WAV, or uncompressed music |

---

## Sources

- https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API
- https://developer.chrome.com/blog/autoplay/
- https://howlerjs.com/
