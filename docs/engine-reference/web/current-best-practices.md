# Web Stack — Current Best Practices

**Last verified:** 2026-08-06

Modern web game patterns that may not be in the LLM's training data. These are
production-ready recommendations as of the pinned stack.

---

## Project Setup

### Ship WebGPU
The most important change since the training cutoff. `WebGPURenderer` went
production-ready in Three.js **r171**, PixiJS v8 is WebGPU-first by design, and
**Safari 26 added WebGPU** — closing the last major browser gap.

Both libraries auto-detect and fall back to WebGL2. Take the default; force a
backend only for a documented reason, and verify the fallback path actually works.

### Both libraries initialize asynchronously
```ts
// PixiJS v8
const app = new Application();
await app.init({ width: 800, height: 600 });

// Three.js WebGPURenderer
const renderer = new WebGPURenderer({ antialias: true });
await renderer.init();
```
Your entry point is `async`. Plan module structure around that.

### Vite 8 + TypeScript 7
Vite 8 ships **Rolldown** (Rust) as one unified bundler — 10–30x faster builds
than the old esbuild+Rollup split. TypeScript 7.0's **native Go compiler** is
8–12x faster than the old one. Re-verify config flags against current docs;
remembered options may have moved.

---

## Architecture

### Fixed timestep, always
Never drive simulation off raw `requestAnimationFrame` delta — physics becomes
frame-rate dependent and a 144Hz monitor plays a different game than a 60Hz one.

```ts
const STEP = 1 / 60;
let accumulator = 0;

function frame(now: number): void {
  const delta = Math.min((now - last) / 1000, 0.25); // clamp for tab refocus
  last = now;
  accumulator += delta;
  while (accumulator >= STEP) {
    world.update(STEP);
    accumulator -= STEP;
  }
  render(accumulator / STEP);
  requestAnimationFrame(frame);
}
```

The clamp matters: a backgrounded tab produces a multi-second delta, and without
it the `while` loop runs thousands of iterations and freezes the page.

### Keep simulation GPU-free
Isolate rendering behind an interface so `world.update()` runs headlessly under
Vitest with no canvas. This is what makes a web game testable in CI without a
software renderer, and it is the single highest-leverage architectural decision.

### Dependency direction
`core` ← `gameplay` ← `ui`. Enforce with ESLint `no-restricted-imports` so
violations fail the build rather than code review.

---

## Performance

### GC is the frame-time killer
On the web, the thing that produces visible stutter is usually not draw calls —
it is a garbage collection pause. Target **zero steady-state allocation** in the
update and render loop.

Allocating patterns to keep out of the loop:
- Object and array literals (`{ x, y }`, `[a, b]`)
- `.map()`, `.filter()`, `.reduce()`, spread
- Closures created per frame
- String concatenation and template literals
- `Array.prototype.sort()` with an inline comparator

Pool vectors, matrices, particles, and projectiles. Reuse scratch objects.

### Dispose explicitly — nothing is automatic
```ts
// Three.js
geometry.dispose(); material.dispose(); texture.dispose();

// PixiJS
container.destroy({ children: true, texture: false });
```
Removing an object from the scene graph does **not** free its GPU memory. Missing
disposal shows up as memory climbing across every level transition until the tab
crashes. Test it by cycling scenes repeatedly and watching memory.

### Payload is the platform constraint
A console game ships 80GB. A web game that takes 20 seconds to load has already
lost the player — on itch.io they are one click from leaving.

| Metric | Target |
|--------|--------|
| Initial JS (gzipped) | < 300 KB |
| Time to first interaction | < 3 s on 4G |
| Total initial download | < 2 MB |

Budget it, then check it in CI. A budget nobody measures is not a budget.

### Compress assets properly
| Asset | Format |
|-------|--------|
| 3D geometry | GLTF + DRACO |
| 3D textures | KTX2 / Basis |
| 2D sprites | Packed atlas, WebP or AVIF |
| Audio | Opus in WebM, AAC fallback |

KTX2/Basis wins twice: smaller download **and** smaller VRAM, which is what stops
mid-range phones from crashing.

---

## Browser Platform Realities

These are unchanged from training data but are still the most commonly missed:

- **Audio needs a user gesture.** Every project needs an explicit "click to start"
  that resumes the `AudioContext`. There is no way around it
- **`100dvh`, never `100vh`** — mobile browser chrome makes `vh` wrong
- **Pointer Events**, not separate mouse/touch handlers — one path covers all
- **Gamepad requires polling** via `navigator.getGamepads()` in the loop; there is no event API
- **`devicePixelRatio`** must factor into canvas sizing, and rendering at full DPR on a 4K display is often not worth the fill-rate cost
- **No asset protection.** Everything shipped is downloadable. Never bundle secrets
- **Clear held input on `blur`/`visibilitychange`** or the player returns to a stuck movement key

---

## Testing

- **Vitest** for unit tests; keep them GPU-free so they run anywhere
- **Playwright** for E2E
- Headless WebGL/WebGPU in CI needs a software renderer (SwiftShader). Minimize
  how much of the suite depends on one
- Determinism: fixed timestep makes simulation reproducible — assert on
  simulation state, not on rendered pixels

---

## Sources

- https://pixijs.com/8.x/guides/migrations/v8
- https://github.com/mrdoob/three.js/releases
- https://vite.dev/blog/announcing-vite8
- https://threejs.org/changelog/
