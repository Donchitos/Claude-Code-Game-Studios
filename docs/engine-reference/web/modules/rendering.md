# Web — Rendering Module Reference

**Last verified:** 2026-08-06
**Knowledge Gap:** WebGPU is production-ready in both libraries; Three's post-processing class was renamed in r183

---

## Overview

| Layer | PixiJS v8 | Three.js r185 |
|-------|-----------|---------------|
| Backend | WebGPU → WebGL2 fallback (auto) | `WebGPURenderer` → `WebGLRenderer` |
| Init | `await app.init()` | `await renderer.init()` |
| Shading | Filters (WGSL + GLSL) | TSL / `NodeMaterial` |
| Post-FX | `Filter` on containers | `RenderPipeline` |

**Both initialize asynchronously.** Entry points must be `async`.

---

## PixiJS Rendering

### Setup
```ts
import { Application } from 'pixi.js';

const app = new Application();
await app.init({
  width: 800,
  height: 600,
  antialias: true,
  autoDensity: true,
  resolution: Math.min(window.devicePixelRatio, 2),
});
document.body.appendChild(app.canvas);   // NOT app.view
```

### Draw-call batching
Draw calls are the primary 2D bottleneck. Pixi batches aggressively; these break a batch:

| Batch breaker | Fix |
|---------------|-----|
| Texture change between siblings | Pack into one atlas |
| Filter on a mid-list child | Apply at container level, or reorder |
| `blendMode` change between siblings | Group by blend mode |
| `Graphics` interleaved with `Sprite` | Separate into layers |

Measure the renderer's draw-call count before and after any change. Do not guess.

### Culling
```ts
container.cullable = true;
container.cullArea = new Rectangle(0, 0, worldWidth, worldHeight);
```
Prefer this over hand-rolled visibility checks for large scrolling worlds.

---

## Three.js Rendering

### Setup
```ts
import { WebGPURenderer } from 'three/webgpu';

const renderer = new WebGPURenderer({ antialias: true });
await renderer.init();
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2)); // cap DPR
renderer.setSize(window.innerWidth, window.innerHeight);
```

Capping `devicePixelRatio` at 2 is standard — beyond it the fill-rate cost rarely
justifies the visual gain, especially on mobile.

### Post-processing — `RenderPipeline`
```ts
// ❌ Pre-r183 — the name that dominates training data
import { PostProcessing } from 'three/webgpu';

// ✅ r183+
import { RenderPipeline } from 'three/webgpu';
const pipeline = new RenderPipeline(renderer);
```

### Instancing
```ts
const mesh = new InstancedMesh(geometry, material, count);
// update matrices in place, then:
mesh.instanceMatrix.needsUpdate = true;
```
- `InstancedMesh` — many copies of one geometry+material → one draw call
- `BatchedMesh` — many *different* geometries sharing a material

Never recreate the mesh per frame.

### Lighting (r185)
`ClusteredLighting` (Forward+ clustered shading) landed on `WebGPURenderer` in
r185, which raises the affordable light count considerably. Verify against
current docs before assuming the old "keep lights under 4" heuristic applies.

Shadows remain expensive regardless — cast from as few lights as possible, and
tune `shadow.camera` bounds tightly to the play area.

---

## Disposal — Applies to Both

Neither library frees GPU memory automatically. Removing an object from the
scene graph does **not** dispose it.

```ts
// Three.js
geometry.dispose();
material.dispose();
texture.dispose();

// PixiJS — texture: false when the atlas is shared
container.destroy({ children: true, texture: false });
```

Symptom of missing disposal: memory climbs across every level transition until
the tab crashes. Test by cycling scenes repeatedly while watching memory.

---

## Resolution and DPR

```ts
// Cap DPR — full DPR on a 4K display is 8M+ fragments per full-screen pass
const dpr = Math.min(window.devicePixelRatio, 2);
```

Rendering post-processing at reduced resolution and upsampling is standard for
bloom, blur, and AO — those effects tolerate it invisibly.

---

## Common Errors

| Symptom | Cause |
|---------|-------|
| `app.view is undefined` | v7 pattern — use `app.canvas` |
| `PostProcessing is not exported` | Renamed to `RenderPipeline` in r183 |
| Renderer methods fail right after construction | Missing `await init()` |
| Memory climbs across scenes | Missing `dispose()` / `destroy()` |
| Framerate tanks on 4K | Uncapped `devicePixelRatio` |
| High draw calls in 2D | Unpacked textures breaking batches |

---

## Sources

- https://pixijs.com/8.x/guides/migrations/v8
- https://github.com/mrdoob/three.js/releases/tag/r185
- https://threejs.org/docs/
