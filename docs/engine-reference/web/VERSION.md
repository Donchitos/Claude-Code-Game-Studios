# Web (PixiJS / Three.js) — Version Reference

**Last verified:** 2026-08-06

| Field | Value |
|-------|-------|
| **Engine** | Web (browser runtime) |
| **Renderer** | [CHOOSE: PixiJS (2D) / Three.js (3D) / Both] |
| **PixiJS Version** | 8.19.0 |
| **Three.js Version** | r185 (`three@0.185.x`) |
| **TypeScript** | 7.0.x |
| **Build Tool** | Vite 8.0.x (Rolldown bundler) |
| **Node.js** | 24.x (Active LTS) |
| **Browser Baseline** | Chrome/Edge 120+, Firefox 121+, Safari 26+ |
| **Graphics API** | WebGPU with WebGL2 fallback |
| **Project Pinned** | 2026-08-06 |
| **Last Docs Verified** | 2026-08-06 |
| **LLM Knowledge Cutoff** | May 2026 |
| **Risk Level** | **HIGH — permanent** (see below) |

---

## Knowledge Gap Warning — Structurally Permanent

Unlike Godot, Unity, and Unreal — which pin a single binary and whose risk level
falls after a model update — the web stack's risk level is **permanently HIGH**.
This is a structural property, not a temporary state:

- **Three.js ships roughly monthly** (r183 → r184 → r185 within 2026 alone) and has
  a documented practice of **removing deprecated code in almost every release**.
  Any model's training cutoff will always sit multiple releases behind current.
- **PixiJS v8 iterates continuously** (8.16 → 8.19 in the first half of 2026).
- **TypeScript 7.0 shipped a completely new native compiler** in August 2026.
- **Vite 8 replaced its bundler entirely** (esbuild/Rollup → Rolldown).

**Never suggest a web API from memory alone.** Always check `deprecated-apis.md`
and `breaking-changes.md` first, and use WebSearch for anything not covered here.

---

## Per-Library Risk Assessment

Risk is assessed per library, not once for the stack.

| Library | Model likely knows | Current | Risk | Primary hazard |
|---------|--------------------|---------|------|----------------|
| **PixiJS** | v8.0–v8.10 | 8.19.0 | MEDIUM | v7 patterns are deeply embedded in training data and are hard breaks in v8 |
| **Three.js** | ~r170–r178 | r185 | **HIGH** | Monthly deprecation removal; `PostProcessing` → `RenderPipeline` rename in r183 |
| **TypeScript** | 5.x | 7.0.x | MEDIUM | New native compiler; `tsc` flags and perf characteristics changed |
| **Vite** | 5.x–6.x | 8.0.x | MEDIUM | Rolldown bundler swap changed plugin and config behavior |
| **Node.js** | 20–22 | 24 LTS | LOW | Additive; few breaks affect game code |

---

## Post-Cutoff Timeline — What Changed

| Release | When | Risk | Key theme |
|---------|------|------|-----------|
| Three.js r171 | Sept 2025 | HIGH | **WebGPURenderer declared production-ready** |
| Three.js r175 | 2025 | MEDIUM | Deprecated code removal pass |
| Three.js r183 | 2026 | **HIGH** | `PostProcessing` renamed to `RenderPipeline` (node-based) |
| Three.js r184 | Apr 2026 | MEDIUM | Incremental; continued TSL expansion |
| Three.js r185 | 2026 | **HIGH** | ClusteredLighting (Forward+), `ExternalTexture`, WebXR-on-WebGPU, further deprecation removal |
| PixiJS 8.16 | Feb 2026 | LOW | Experimental Canvas renderer; tagged text |
| PixiJS 8.17 | Mar 2026 | LOW | Optimized `BlurFilter`; `visibleChanged` event |
| PixiJS 8.18 | Apr 2026 | LOW | `graphicsContextToSvg()` |
| PixiJS 8.19 | Jun 2026 | LOW | Incremental |
| TypeScript 7.0 | Aug 2026 | MEDIUM | Native Go compiler, 8–12x faster builds |
| Vite 8.0 | Apr 2026 | MEDIUM | Rolldown as the single unified bundler |

---

## The Single Most Important Fact

**WebGPU is now shippable to all users.** Three.js `WebGPURenderer` went
production-ready in r171, PixiJS v8 is WebGPU-first by design, and Safari 26
added WebGPU support — closing the last major gap. Advice from the training-data
era that says "WebGPU is experimental, use WebGL" is **out of date**. The current
guidance is WebGPU with an automatic WebGL2 fallback, which both libraries do
by default.

---

## Verified Sources

- PixiJS releases: https://github.com/pixijs/pixijs/releases
- PixiJS v8 migration guide: https://pixijs.com/8.x/guides/migrations/v8
- Three.js releases: https://github.com/mrdoob/three.js/releases
- Three.js migration guide: https://github.com/mrdoob/three.js/wiki/Migration
- Three.js changelog: https://threejs.org/changelog/
- Vite 8 announcement: https://vite.dev/blog/announcing-vite8
- Node.js release schedule: https://nodejs.org/en/blog/announcements/evolving-the-nodejs-release-schedule
