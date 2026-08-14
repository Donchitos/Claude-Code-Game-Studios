# Web Stack — Breaking Changes

**Last verified:** 2026-08-06

Breaking API changes and behavioral differences between what the model likely
learned and the currently pinned stack. Organized by library, then risk level.

---

# PixiJS

## HIGH RISK — v7 Patterns That Are Hard Breaks in v8

The model's training data contains a large volume of PixiJS v7 code. These
patterns **will not run** on v8.

### Application initialization is now asynchronous

Detecting WebGPU vs WebGL2 requires an async handshake, so the renderer can no
longer be built in a constructor.

```ts
// ❌ OLD (v7): synchronous constructor
const app = new PIXI.Application({ width: 800, height: 600 });
document.body.appendChild(app.view);

// ✅ NEW (v8): async init, and `view` is now `canvas`
import { Application } from 'pixi.js';

const app = new Application();
await app.init({ width: 800, height: 600 });
document.body.appendChild(app.canvas);
```

**Migration:** every entry point becomes async. `app.view` → `app.canvas`.

---

### `BaseTexture` no longer exists

```ts
// ❌ OLD (v7)
const base = new PIXI.BaseTexture('sprite.png');
const texture = new PIXI.Texture(base);

// ✅ NEW (v8): load through Assets; Texture expects a loaded resource
import { Assets, Sprite } from 'pixi.js';

const texture = await Assets.load('sprite.png');
const sprite = new Sprite(texture);
```

**Why:** in v8 textures no longer know how to load anything. Loading is the
`Assets` manager's job, and `Texture` wraps an already-resolved
`TextureSource`. Constructing a `Texture` from a URL string silently produced
an unloaded texture in v7; in v8 it is simply not supported.

---

### The global `PIXI` namespace is gone

```ts
// ❌ OLD (v7)
const sprite = new PIXI.Sprite(texture);

// ✅ NEW (v8): named ESM imports from the single package
import { Sprite } from 'pixi.js';
const sprite = new Sprite(texture);
```

v8 also reverted to a **single package** — do not install `@pixi/*` sub-packages.

---

### Only `Container` can have children

```ts
// ❌ OLD (v7): Sprite could parent other display objects
sprite.addChild(childSprite);

// ✅ NEW (v8): use an explicit Container
const group = new Container();
group.addChild(sprite, childSprite);
```

---

### `ParticleContainer` reworked

`ParticleContainer` no longer accepts `Sprite` children. It takes particle
records instead, which is what allows the far higher particle counts in v8.
Any v7 particle code needs rewriting, not adjusting.

---

## MEDIUM RISK — Behavioral Changes

### WebGPU is the default renderer
v8 auto-detects and prefers WebGPU, falling back to WebGL2. Shader code written
against a WebGL-only assumption may need a WGSL counterpart. Force a backend
with `await app.init({ preference: 'webgl' })` only when a specific reason
demands it.

---

# Three.js

## HIGH RISK — Renamed and Removed

### `PostProcessing` → `RenderPipeline` (r183)

```ts
// ❌ OLD (pre-r183)
import { PostProcessing } from 'three/webgpu';
const post = new PostProcessing(renderer);

// ✅ NEW (r183+)
import { RenderPipeline } from 'three/webgpu';
const pipeline = new RenderPipeline(renderer);
```

**Why:** the class was renamed to reflect that it drives the whole render
pipeline, not just a post-pass. This is the single most likely stale API an
agent will suggest, because the old name dominates training data.

---

### Deprecated code is removed almost every release

r175 and r185 each ran a deprecation-removal pass, and this is routine practice
rather than an exception. An API that merely warned in the version the model
learned may be **absent** in r185.

**Rule:** before suggesting any Three.js API you have not verified in this
reference set, check `deprecated-apis.md`, then WebSearch the current docs.

---

### `Matrix3.scale()` / `.rotate()` / `.translate()` deprecated (r185)

Marked for removal. Compose the transform explicitly rather than mutating
through these helpers.

---

### Loader changes (r185)

| Change | Action |
|--------|--------|
| `DRACOLoader.setDecoderConfig()` deprecated | Configure the decoder through the current documented path |
| `LWOLoader` deprecated | Convert assets to glTF |

---

## MEDIUM RISK — WebGPU Is Now the Recommended Path

`WebGPURenderer` has been production-ready since **r171** (Sept 2025), and
Safari 26 shipping WebGPU closed the last browser gap. Training-era advice to
treat WebGPU as experimental is out of date.

```ts
// Current recommended setup
import { WebGPURenderer } from 'three/webgpu';
const renderer = new WebGPURenderer({ antialias: true });
await renderer.init(); // async, like PixiJS v8
```

`WebGLRenderer` remains supported. Choosing it is now a deliberate
compatibility decision, not the default.

**New in r185 for WebGPU:** `ClusteredLighting` (Forward+ clustered shading),
render-to-texture-array, full `ExternalTexture` support, and WebXR on WebGPU.

---

### TSL (Three Shading Language) is the node-material path

TSL continues to expand each release. r185 added `textureGather`,
`textureGatherCompare`, `storageTexture3D`, an `ambientOcclusion` property, and
made vector `not()` component-wise. TSL — not raw GLSL strings — is the
supported way to author materials for `WebGPURenderer`.

---

# Toolchain

## TypeScript 7.0 (Aug 2026) — MEDIUM RISK

TypeScript 7.0 replaced the compiler with a **native Go implementation**,
delivering 8–12x faster builds. Type-checking semantics are intended to be
compatible, but build tooling, flags, and editor integration changed. Verify
`tsconfig.json` options against current docs rather than memory.

## Vite 8.0 (Apr 2026) — MEDIUM RISK

Vite 8 ships **Rolldown** (Rust) as its single unified bundler, replacing the
esbuild-plus-Rollup split, with 10–30x faster builds. Plugin compatibility is
broadly maintained, but any custom Rollup plugin behavior and bundler-specific
config should be re-verified.

## Node.js 24 LTS

Node 24 is the Active LTS line; Node 26 enters LTS in October 2026. Node is used
only for tooling and CI here, not at runtime, so risk to game code is low.

---

## Sources

- https://pixijs.com/8.x/guides/migrations/v8
- https://github.com/pixijs/pixijs/releases
- https://github.com/mrdoob/three.js/releases
- https://github.com/mrdoob/three.js/wiki/Migration
- https://vite.dev/blog/announcing-vite8
