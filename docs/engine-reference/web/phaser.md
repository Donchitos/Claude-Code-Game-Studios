# Phaser 4 — What Changed

Last verified: 2026-10-29 | Pinned: `phaser` 4.2.1

Phaser 4.0.0 came out on 2026-04-10. The model knows Phaser 3 (to about
3.88) and writes Phaser 3 code by default. The renderer was rewritten; a game
that uses only the standard API (sprites, text, tilemaps) should run
unchanged **[S]** (1). These are the lines that break.

**Grades:** **[S]** sourced — read in the named primary source on the date
above; **[J]** judgment.

## Setup

- Import as `import * as Phaser from 'phaser'`. The ESM build has named
  exports; its default export was missing in 4.0.0 and added in 4.1.0, so the
  namespace import works on every 4.x. **[S]** (2, npm)
- Types ship in the package (`types/phaser.d.ts`). **[S]** (npm)
- WebGL is the renderer to use; the Canvas renderer still exists but is
  deprecated and supports none of the new rendering features. **[S]** (1)

## Phaser 3 code that breaks

| Phaser 3 | Phaser 4 | |
|----------|----------|---|
| Pipelines, `setPipeline()`, custom `WebGLPipeline` | Removed. Custom rendering is a render node (`RenderConfig#renderNodes`) | **[S]** |
| `sprite.setPipeline('Light2D')` | `sprite.setLighting(true)`; lights have a `z` height | **[S]** |
| `preFX`, `postFX` | One **Filter** system: `obj.filters.internal` / `obj.filters.external`, on any game object or camera | **[S]** |
| `BitmapMask`, `setMask(mask)` | `sprite.filters.internal.addMask(maskObject)`; `GeometryMask` is Canvas-only | **[S]** |
| Bloom / Shine / Circle FX | `Phaser.Actions.AddEffectBloom()`, `AddEffectShine()`, `AddMaskShape()` | **[S]** |
| Gradient FX | `Gradient` game object | **[S]** |
| `colorMatrix.sepia()` | `colorMatrix.colorMatrix.sepia()` | **[S]** |
| `setTintFill(c)`, `tintFill` | `setTint(c).setTintMode(Phaser.TintModes.FILL)`; `setTint()` no longer turns fill off | **[S]** |
| `Phaser.Geom.Point` | Removed: `Phaser.Math.Vector2`. Geometry helpers (`getPoint`, `Random`, …) return `Vector2` | **[S]** |
| `Phaser.Math.TAU` = π/2 | `TAU` = 2π now; `PI_OVER_2` = π/2; `PI2` removed | **[S]** |
| `Phaser.Structs.Set` / `Map` | Native `Set` / `Map` | **[S]** |
| `roundPixels: true` default | Defaults to `false`; per object: `vertexRoundMode` | **[S]** |
| `Mesh`, `Plane`, Camera3D, Layer3D | Removed (4.2 adds a 2D `Mesh2D`) | **[S]** |
| `DynamicTexture` / `RenderTexture` drew at once | Commands are buffered: call `render()` | **[S]** |
| `new Shader(scene, key, …)` | Takes a config object; Shadertoy uniforms are no longer set for you | **[S]** |
| Facebook plugin, `phaser-ie9.js`, `Create.GenerateTexture`, polyfills | Removed | **[S]** |
| Raw `gl` calls | Never: they desync the renderer's state; use an `Extern` game object | **[S]** |

- Texture coordinates are GL-style (Y = 0 at the bottom) in custom shaders,
  and compressed textures must be re-made flipped; PNG and JPG need nothing.
  **[S]** (1)
- `TileSprite` no longer crops its texture, and now takes atlas frames and
  `tileRotation`. **[S]** (1)
- Camera matrices were rewritten (`matrix` now includes scroll;
  `matrixExternal`, `matrixCombined`); code using only `scrollX`, `scrollY`,
  `zoom` and `rotation` is unaffected. **[S]** (1)
- `Grid` uses stroke (not outline) properties; `Rectangle` has rounded
  corners. **[S]** (1)

## 4.1 and 4.2

- 4.1: `Layer` is a true `GameObject` (filters work on it); a filter
  controller's `getPadding()` → `getPaddingCeil()` in custom filter code.
  **[S]** (2)
- 4.2: `Mesh2D`, `Stencil` (persistent stencil masks), `CustomContext`,
  cone lights, a second tint (`setTint2()`); config `render.stencil`,
  `render.alphaStrategy`. The `inTintEffect` shader attribute is a `vec4` now
  (custom render nodes only). **[S]** (2)

## Driving the game from a test

Phaser runs its own loop (`game.loop`, a `TimeStep` on requestAnimationFrame).
`game.loop.sleep()` stops it and `game.step(time, delta)` advances one frame
(delta in milliseconds), which is how a scripted check can step it. **[S]**
that both methods exist in 4.2.1 (3); **[J]** that this gives repeatable runs
— not verified: show two same-seed runs match before calling a replay exact.

## Sources

1. https://github.com/phaserjs/phaser/blob/master/changelog/v4/4.0/MIGRATION-GUIDE.md
2. https://github.com/phaserjs/phaser/releases (v4.0.0, v4.1.0, v4.2.0, v4.2.1)
3. https://github.com/phaserjs/phaser/blob/v4.2.1/src/core/Game.js ; `src/core/TimeStep.js`

npm: `registry.npmjs.org/phaser` (versions, `exports`, `types`).
