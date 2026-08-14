# Web Stack — Optional Packages & Ecosystem

**Last verified:** 2026-08-06

This document indexes **optional npm packages** commonly used in browser games.
These are NOT part of PixiJS or Three.js core.

---

## How to Use This Guide

**🟡 Brief Overview** — links to official docs; use WebSearch for current API detail
**⚠️ Evaluate** — viable but check maintenance status before adopting
**📦 npm** — install via npm/pnpm

> **Bundle-size discipline**: every package here adds to the payload, and payload
> is the web's binding constraint. Before adding any dependency, get
> `web-platform-specialist` to assess its gzipped cost and tree-shakeability.
> A package that adds 80 KB to satisfy one function is not worth it.

---

## Physics

### 🟡 Rapier
- **Purpose:** Rust/WASM physics engine, 2D and 3D
- **When to use:** any project needing real rigid-body physics
- **Why this one:** actively maintained, deterministic (important for replays and netcode), and far faster than JS-native engines
- **Cost:** WASM binary adds meaningfully to payload — load it async, not in the boot bundle
- **Package:** `@dimforge/rapier2d` / `@dimforge/rapier3d`
- **Official:** https://rapier.rs/

### ⚠️ Cannon-es
- **Purpose:** pure-JS 3D physics, a maintained fork of the original cannon.js
- **When to use:** light physics needs where a WASM payload isn't justified
- **Trade-off:** slower and less accurate than Rapier
- **Package:** `cannon-es`

### 🟡 Matter.js
- **Purpose:** pure-JS 2D physics
- **When to use:** 2D games where approachability beats performance
- **Package:** `matter-js`

---

## Audio

### 🟡 Howler.js
- **Purpose:** audio abstraction over Web Audio with sprite support and format fallback
- **When to use:** most projects — it handles the autoplay-unlock dance, audio sprites, and codec fallback that are tedious to hand-roll
- **Knowledge gap:** none significant; the library is stable
- **Package:** `howler`
- **Official:** https://howlerjs.com/

> Raw Web Audio is entirely viable and adds nothing to the bundle. Prefer it when
> audio needs are simple. See `modules/audio.md`.

---

## Networking / Multiplayer

### 🟡 Colyseus
- **Purpose:** authoritative multiplayer server framework with room-based state sync
- **When to use:** real-time multiplayer where you control the server
- **Note:** requires hosting a Node server — this is a significant infrastructure commitment beyond static hosting
- **Package:** `colyseus.js` (client)
- **Official:** https://colyseus.io/

### 🟡 Geckos.io
- **Purpose:** UDP-like unreliable messaging over WebRTC data channels
- **When to use:** fast-paced action multiplayer where WebSocket latency and head-of-line blocking hurt
- **Package:** `@geckos.io/client`

See `modules/networking.md` for the WebSocket vs WebRTC decision.

---

## PixiJS Ecosystem

### 🟡 pixi-filters
- **Purpose:** a large collection of ready-made display filters (glow, outline, CRT, shockwave, etc.)
- **When to use:** before writing a custom filter — check here first
- **Important:** verify each filter provides **both** WGSL and GLSL sources for v8 backend parity
- **Package:** `pixi-filters`

### 🟡 @pixi/sound
- **Purpose:** audio integrated with the Pixi `Assets` loader
- **When to use:** Pixi projects wanting one asset pipeline for audio and textures
- **Package:** `@pixi/sound`

---

## Three.js Ecosystem

### 🟡 three/addons (bundled examples)
- **Purpose:** loaders (GLTF, DRACO, KTX2), controls (Orbit, Pointer Lock), and helpers
- **When to use:** constantly — `GLTFLoader`, `DRACOLoader`, and `KTX2Loader` all live here
- **Note:** these ship with `three` but are **not** in the main entry point. Import from `three/addons/...` and verify tree-shaking
- **Official:** https://threejs.org/docs/

### 🟡 postprocessing (pmndrs)
- **Purpose:** a merged-pass post-processing library for the WebGL path
- **When to use:** WebGL projects wanting effects with fewer full-screen passes than naive chaining
- **⚠️ Important:** on the **WebGPU** path, use Three's built-in **`RenderPipeline`** (renamed from `PostProcessing` in r183) rather than this library
- **Package:** `postprocessing`

### 🟡 three-mesh-bvh
- **Purpose:** accelerated raycasting and spatial queries
- **When to use:** frequent raycasts against complex geometry (picking, projectiles, character controllers)
- **Package:** `three-mesh-bvh`

---

## Tooling

### 🟡 gltf-transform / gltfpack
- **Purpose:** CLI GLTF optimization — DRACO compression, texture conversion, mesh simplification
- **When to use:** always, as a build step for any 3D project
- **Why:** the single highest-leverage payload reduction available to a web 3D game

### 🟡 TexturePacker / free atlas packers
- **Purpose:** sprite atlas generation
- **When to use:** any 2D project — individual PNGs multiply draw calls and requests

### 🟡 vite-plugin-pwa
- **Purpose:** service worker and offline support
- **When to use:** only if offline play or installability is a real requirement — it adds cache-invalidation complexity

---

## Validation

### 🟡 Zod
- **Purpose:** runtime schema validation with type inference
- **When to use:** at every external boundary — level JSON, save data, `localStorage`, network messages
- **Why:** TypeScript types vanish at runtime; anything crossing a boundary is `unknown` until parsed
- **Package:** `zod`

---

## Sources

- https://rapier.rs/
- https://howlerjs.com/
- https://colyseus.io/
- https://threejs.org/docs/
- https://pixijs.com/
