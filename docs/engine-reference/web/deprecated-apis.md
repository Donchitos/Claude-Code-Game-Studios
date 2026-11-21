# Web — Deprecated APIs

Last verified: 2026-10-29 (the date of the pages each row comes from)

Every row is copied from another page in this folder, named in the Source
column. That page has the detail and the primary source. Nothing here is new.

If an agent suggests any API in the "Deprecated" column, it MUST be replaced
with the "Use Instead" column.

## three.js

| Deprecated | Use Instead | Since | Source |
|------------|-------------|-------|--------|
| `Clock` | `Timer` (`THREE.Timer`, in core since r179) | r183 | `threejs.md` |
| `PCFSoftShadowMap` on `WebGLRenderer` | `PCFShadowMap` (now soft too) or `VSMShadowMap` | r182 | `threejs.md` |
| `ColorManagement.fromWorkingColorSpace()` / `toWorkingColorSpace()` | `workingToColorSpace()` / `colorSpaceToWorking()` | r177 | `threejs.md` |
| `WebGLRenderer({ reverseDepthBuffer })` | `reversedDepthBuffer` | r179 | `threejs.md` |
| `RGBELoader` | `HDRLoader` | r180 | `threejs.md` |
| `RGBMLoader` | — | r180 | `threejs.md` (removed) |
| `SVGLoader.createShapes()` | `toShapes()` on each shape path | r185 | `threejs.md` |
| `DRACOLoader.setDecoderConfig()`, `LWOLoader`, `VTKLoader` | — | r184–r185 | `threejs.md` (deprecated) |
| `Source` | `TextureSource` | r186 | `threejs.md` |
| `WebGPURenderer` `*Async()` methods (`renderAsync`, `computeAsync`, …) | `setAnimationLoop()`, or `await renderer.init()` first | r181 | `threejs.md` |
| `WebGPURenderer` `colorBufferType` | `outputBufferType` | r182 | `threejs.md` |
| `PostProcessing` / `WebGLCubeRenderTarget` (WebGPU) | `RenderPipeline` / `CubeRenderTarget` | r183 | `threejs.md` |
| `LightProbeGrid` (WebGPU) | `LightProbeGridWebGL` | r186 | `threejs.md` |

## Phaser 4

| Deprecated | Use Instead | Since | Source |
|------------|-------------|-------|--------|
| Canvas renderer | WebGL renderer | 4.0 | `phaser.md` (deprecated) |
| Pipelines, `setPipeline()`, custom `WebGLPipeline` | A render node (`RenderConfig#renderNodes`) | 4.0 | `phaser.md` |
| `sprite.setPipeline('Light2D')` | `sprite.setLighting(true)` | 4.0 | `phaser.md` |
| `preFX`, `postFX` | `obj.filters.internal` / `obj.filters.external` | 4.0 | `phaser.md` |
| `BitmapMask`, `setMask(mask)` | `sprite.filters.internal.addMask(maskObject)` | 4.0 | `phaser.md` |
| `setTintFill(c)`, `tintFill` | `setTint(c).setTintMode(Phaser.TintModes.FILL)` | 4.0 | `phaser.md` |
| `Phaser.Geom.Point` | `Phaser.Math.Vector2` | 4.0 | `phaser.md` |
| `Phaser.Math.TAU` as π/2, `PI2` | `PI_OVER_2` (π/2); `TAU` is now 2π | 4.0 | `phaser.md` |
| `Phaser.Structs.Set` / `Map` | Native `Set` / `Map` | 4.0 | `phaser.md` |
| `Mesh`, `Plane`, Camera3D, Layer3D | — (4.2 adds a 2D `Mesh2D`) | 4.0 | `phaser.md` (removed) |
| Facebook plugin, `phaser-ie9.js`, `Create.GenerateTexture` | — | 4.0 | `phaser.md` (removed) |

## PixiJS 8

| Deprecated | Use Instead | Since | Source |
|------------|-------------|-------|--------|
| `new Application({ … })` | `new Application()` then `await app.init({ … })` | 8.0 | `pixijs.md` |
| `app.view` | `app.canvas` | 8.0 | `pixijs.md` |
| `@pixi/app`, `@pixi/sprite`, … | `import { … } from 'pixi.js'` | 8.0 | `pixijs.md` |
| `beginFill().drawRect().endFill()`, `lineStyle()` | `new Graphics().rect(…).fill(…).stroke({ … })` | 8.0 | `pixijs.md` |
| `settings.RESOLUTION = …` | Options to `init()` | 8.0 | `pixijs.md` |
| `DisplayObject` | `Container` | 8.0 | `pixijs.md` |
| `BaseTexture` | `TextureSource` | 8.0 | `pixijs.md` |
| `cacheAsBitmap = true` | `cacheAsTexture()` | 8.0 | `pixijs.md` |
| `updateTransform()` per-frame hook | — | 8.0 | `pixijs.md` (removed) |
| `TextureGCSystem` / `RenderableGCSystem` | `GCSystem` | 8.15 | `pixijs.md` |
| `isUniform` in custom shader structs | `accessMode` | 8.20 | `pixijs.md` |
| `frontFaceInverted` | `renderTarget.isFrontFaceInverted()` | 8.21 | `pixijs.md` |

## Toolchain

| Deprecated | Use Instead | Since | Source |
|------------|-------------|-------|--------|
| `splitVendorChunkPlugin`, Sass legacy API | — | Vite 7 | `breaking-changes.md` (removed) |
| `build.rollupOptions`, `worker.rollupOptions` | `build.rolldownOptions`, `worker.rolldownOptions` | Vite 8 | `breaking-changes.md` |
| `esbuild: {…}` | `oxc: {…}` | Vite 8 | `breaking-changes.md` |
| `optimizeDeps.esbuildOptions` | `optimizeDeps.rolldownOptions` | Vite 8 | `breaking-changes.md` |
| `build.minify: 'esbuild'` | Oxc (the default) | Vite 8 | `breaking-changes.md` |
| `output.manualChunks` | Rolldown `codeSplitting` | Vite 8 | `breaking-changes.md` |
| `transformWithEsbuild` | `transformWithOxc` | Vite 8 | `breaking-changes.md` |
| `server.hmr` WebSocket options (`protocol`, `host`, `port`, …) | `server.ws` | Vite 8.1 | `breaking-changes.md` |
| `moduleResolution: node`/`node10`/`classic` | `bundler` or `nodenext` | TypeScript 6.0 (error in 7.0) | `breaking-changes.md` |
| `baseUrl` | `paths` relative to the project root | TypeScript 6.0 (error in 7.0) | `breaking-changes.md` |
| `import … asserts {…}` | `import … with {…}` | TypeScript 6.0 (error in 7.0) | `breaking-changes.md` |
| Vitest `workspace` | `projects` in `vitest.config.ts` | Vitest 4 | `breaking-changes.md` |
| Vitest `maxThreads` / `maxForks` | `maxWorkers` | Vitest 4 | `breaking-changes.md` |
| `test(name, fn, { … })` options as third argument | `test(name, { … }, fn)` | Vitest 4 | `breaking-changes.md` |
| `test.sequential`, `describe.sequential` | — | Vitest 5 | `breaking-changes.md` (removed) |
| Playwright `page.accessibility` | Axe | 1.57 | `breaking-changes.md` |
| Playwright `videosPath` / `videoSize` | `recordVideo` | 1.60 | `breaking-changes.md` |
