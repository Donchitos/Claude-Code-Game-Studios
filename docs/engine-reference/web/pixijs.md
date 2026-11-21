# PixiJS 8 — What Changed

Last verified: 2026-10-29 | Pinned: `pixi.js` 8.22.0

PixiJS 8 came out in 2024, before the model's training ended, but the model
still writes v7 code often; the v8 rules come first. Releases 8.10 to 8.22
(2025-06 to 2026-10) are after the cutoff: additive, with a few behaviour
changes listed below.

**Grades:** **[S]** sourced — read in the named primary source on the date
above; **[J]** judgment.

## v8 rules the model gets wrong

| v7 | v8 | |
|----|----|---|
| `new Application({ width, … })` | `const app = new Application(); await app.init({ width, … })` | **[S]** |
| `app.view` | `app.canvas` | **[S]** |
| `@pixi/app`, `@pixi/sprite`, … | One package: `import { Application, Sprite } from 'pixi.js'` (sub-paths such as `pixi.js/gif` still exist) | **[S]** |
| `beginFill().drawRect().endFill()`, `lineStyle()` | Shape then style: `new Graphics().rect(x, y, w, h).fill(0xff0000).stroke({ width: 2, color: 'white' })` | **[S]** |
| `Texture.from(url)` loads | Load first: `await Assets.load(url)`, then `Texture.from(url)` | **[S]** |
| `ticker.add((dt) => …)` | The callback gets the `Ticker`: `ticker.add((t) => … t.deltaTime …)` | **[S]** |
| `settings.RESOLUTION = …` | `settings` removed; pass options to `init()` | **[S]** |
| `DisplayObject` | Removed: `Container` is the base class | **[S]** |
| A `Sprite` with children | Only `Container`s have children; wrap leaves in a `Container` | **[S]** |
| `BaseTexture` | `TextureSource` and its subclasses | **[S]** |
| `cacheAsBitmap = true` | `cacheAsTexture()` | **[S]** |
| `getBounds()` was a `Rectangle` | `getBounds().rectangle` | **[S]** |
| `updateTransform()` per-frame hook | Removed | **[S]** |
| default `eventMode: 'auto'` | Default is `'passive'` **[S]**: set `eventMode = 'static'` on what is clicked **[J]** | |

## 8.10 – 8.22 changes that alter behaviour

- 8.12: `BitmapText` `lineHeight` corrected; text may shift slightly. **[S]**
- 8.15: `TextureGCSystem` / `RenderableGCSystem` deprecated for `GCSystem`. **[S]**
- 8.16: `Container.cullArea` is in the container's local space; `Text` with
  `align: 'right'`/`'center'` moves slightly; `SplitBitmapText` defaults to a
  white fill. **[S]**
- 8.17: `BlurFilter` uses a new halving strength scheme and looks different
  (`new BlurFilter({ legacy: true })` for the old look); justified text uses
  `wordWrapWidth`. **[S]**
- 8.18: word-wrapped text with non-left `align` reports its real rendered
  `width` (was `wordWrapWidth`). **[S]**
- 8.19: `ParticleContainer` inherits its ancestors' blend mode. **[S]**
- 8.20: `isUniform` → `accessMode` in custom shader structs (the old property
  reads `undefined`, no error). **[S]**
- 8.21: `Matrix.decompose()` and reparenting turn a mirrored matrix into a
  rotation with negative `scale.x` (was skew); `frontFaceInverted` deprecated
  for `renderTarget.isFrontFaceInverted()`. **[S]**
- 8.22: Tab activates the accessibility layer again by default
  (`activateOnTab`), as documented. **[S]**
- `deprecation.quiet = true` (8.13) silences deprecation warnings. **[S]**

All from the GitHub release notes (2).

## Driving the game from a test

`await app.init({ autoStart: false })` keeps the ticker stopped, so a check
can advance the game itself and call `app.render()`. **[S]** that `autoStart`
and `app.render()` exist in 8.22.0 (3); **[J]** for its use in repeatable runs — not verified:
show two same-seed runs match before calling a replay exact.

## Sources

1. https://pixijs.com/8.x/guides/migrations/v8
2. https://github.com/pixijs/pixijs/releases (v8.10.0 – v8.22.0)
3. https://github.com/pixijs/pixijs/blob/v8.22.0/src/app/TickerPlugin.ts

npm: `registry.npmjs.org/pixi.js`.
