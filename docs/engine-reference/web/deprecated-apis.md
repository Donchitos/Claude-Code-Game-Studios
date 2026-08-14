# Web Stack — Deprecated APIs

**Last verified:** 2026-08-06

Quick lookup. Format: **Don't use X** → **Use Y instead**.

Check this file **before suggesting any PixiJS or Three.js API**. Three.js removes
deprecated code in most releases, so "deprecated" here often means "already gone".

---

## PixiJS — v7 → v8

| Deprecated / Removed | Replacement | Notes |
|----------------------|-------------|-------|
| `new PIXI.Application({...})` (sync) | `const app = new Application(); await app.init({...})` | Init is async in v8 |
| `app.view` | `app.canvas` | Aligns with HTML5 naming |
| `PIXI.*` global namespace | Named ESM imports from `pixi.js` | No global bundle wrapper |
| `@pixi/sprite`, `@pixi/core`, other sub-packages | Single `pixi.js` package | v8 reverted to one package |
| `BaseTexture` | `TextureSource` variants via `Assets.load()` | `BaseTexture` no longer exists |
| `new Texture('url.png')` | `await Assets.load('url.png')` | Textures require loaded resources |
| `Texture.from(url)` for unloaded assets | `Assets.load(url)` | `Texture.from` no longer triggers loading |
| `sprite.addChild(...)` | `container.addChild(...)` | Only `Container` may have children |
| `ParticleContainer` with `Sprite` children | `ParticleContainer` with particle records | Fully reworked in v8 |
| `Loader` / `PIXI.Loader` | `Assets` | Assets manager replaces the v7 loader |
| `app.renderer.plugins.interaction` | `app.stage.eventMode` + federated events | Event system replaced in v7/v8 |

---

## Three.js — Removed or Deprecated by r185

| Deprecated / Removed | Replacement | Version | Notes |
|----------------------|-------------|---------|-------|
| `PostProcessing` (from `three/webgpu`) | `RenderPipeline` | r183 | **Straight rename.** Highest-frequency stale suggestion |
| `Matrix3.scale()` | Compose the matrix explicitly | r185 | Deprecated, slated for removal |
| `Matrix3.rotate()` | Compose the matrix explicitly | r185 | Deprecated, slated for removal |
| `Matrix3.translate()` | Compose the matrix explicitly | r185 | Deprecated, slated for removal |
| `DRACOLoader.setDecoderConfig()` | Current documented decoder configuration | r185 | Deprecated |
| `LWOLoader` | Convert source assets to glTF | r185 | Deprecated |
| Raw GLSL `ShaderMaterial` on `WebGPURenderer` | TSL / `NodeMaterial` | r171+ | GLSL strings are not the WebGPU path |
| Treating `WebGPURenderer` as experimental | It is production-ready | r171 | Training-era advice is stale |

### Standing warning

Three.js ran deprecation-removal passes in **r175** and **r185**, and does so
routinely. If an API is not documented in this reference set and you learned it
from training data, **verify it via WebSearch before suggesting it**. An API that
merely logged a warning in r17x may not exist in r185.

---

## Toolchain

| Deprecated | Replacement | Notes |
|------------|-------------|-------|
| `tsc` legacy JS compiler assumptions | TypeScript 7.0 native (Go) compiler | 8–12x faster; re-verify flags |
| Vite esbuild + Rollup two-bundler model | Rolldown (single unified bundler) | Vite 8.0 |
| Node 20 / 22 as the target | Node 24 Active LTS | Node 26 enters LTS Oct 2026 |

---

## Browser APIs — Advice That Aged Out

| Stale advice | Current reality |
|--------------|-----------------|
| "WebGPU is experimental — ship WebGL" | WebGPU is shippable to all users; Safari 26 closed the gap |
| "Use `AudioContext` freely on load" | Autoplay policy requires a user gesture before audio starts — unchanged, still routinely missed |
| "Use `window.innerWidth` for canvas sizing" | Account for `devicePixelRatio` and `visualViewport` on mobile |
| "`100vh` for a full-height canvas" | Use `100dvh` — mobile browser chrome breaks `vh` |

---

## Sources

- https://pixijs.com/8.x/guides/migrations/v8
- https://github.com/mrdoob/three.js/wiki/Migration
- https://github.com/mrdoob/three.js/releases/tag/r185
- https://threejs.org/changelog/
