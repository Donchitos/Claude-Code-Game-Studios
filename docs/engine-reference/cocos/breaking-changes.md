# Cocos Creator — Breaking Changes

Last verified: 2026-06-27 | Engine: Cocos Creator 3.8.6

## Major Architecture Breaks

### v2.x → v3.0 (Major Rewrite)

The v3.0 release was a **complete rewrite of the engine architecture**. The v2.4 → v3.0 migration is the largest break in Cocos Creator history and is not API-compatible.

- **`cc.Class({...})` → ES module TypeScript** — JavaScript class-based syntax replaced by `class Foo extends Component` with `@ccclass` / `@property` decorators
- **Module system** — Moved from global `cc.*` namespace to ES module imports: `import { Component, Node } from 'cc'`
- **`cc.loader` → `assetManager`** — Entire resource loading module replaced (deprecated since v2.4, removed in v3.0)
- **`cc.loader.loadRes()` → `resources.load()`** — Module split into `resources` (for `assets/resources/` folder) and `assetManager` (for bundles, downloads, general)
- **`node.x` → `node.position.x`** — Direct property access removed; use `node.position` getter then `.x` on the returned Vec3
  - **(Re-added in 3.8.6)**: `node.x`, `node.y`, `node.z` getter/setter shortcuts restored via property descriptors — see `modules/animation.md` for usage notes
- **`cc.find()` restrictions** — Performance-sensitive; discourage in production hot paths
- **`cc.AudioEngine` → `AudioSource` component** — Audio playback moved to component-based API
- **2D / 3D unified** — v2.x had separate 2D and 3D products; v3.0 unified them. All projects now use the same engine core.
- **Coordinate system** — v2.x used bottom-left origin in some contexts; v3.0 standardized to top-left for 2D UI, bottom-left for 3D

### v3.0 → v3.5

- **Material / Effect system rewrite** — `YAML`-based effect format replaced with the current `CCEffect` + `CCProgram` GLSL-like structure
- **Custom render pipeline foundation** — Early `RenderPipeline` API introduced (later stabilized in 3.8)
- **Animation retargeting** — AnimationClip format updated; old clips may need re-export

### v3.5 → v3.8

- **Procedural Animation** — New animation system added; `AnimationClip` extended; legacy timeline still supported
- **Custom Render Pipeline (full)** — `CustomRenderPipelineBuilder` and custom stages API stabilized
- **Character Controller** — New built-in component (`CharacterController`) replacing community patterns
- **High Precision Text** — `Label` rendering precision improved; existing bitmap font caches may need rebuild
- **`settings.querySettings`** — New editor settings API; replaced many `Editor.*` calls in editor extensions

### v3.8.0 → v3.8.6 (Recent)

- **`node.x` / `node.y` / `node.z` restored** — Direct property accessors added back; prefer `setPosition()` for performance-critical loops
- **`getComponent<T>()`** — Generic form added: `node.getComponent<PlayerController>('PlayerController')` returns typed result; old `as PlayerController` cast no longer needed
- **`isValid` type** — Type signature tightened; runtime semantics unchanged
- **`js.isNumber` / `js.isString`** — Type signatures improved
- **`UIComponent` type** — Restored from `as any` in `ui-component.ts`; now properly typed
- **2D Assembler refactor** — Internal refactor; affects custom 2D renderers that extend `Assembler2D` directly (rare)
- **Box2D JSB** — New `Box2D JSB` (C++ native) variant added; existing Box2D TS and WASM variants still work; choose per project

## Migration Checklist (v3.7 → v3.8.x)

If your project is on v3.7.x:

1. **Back up the project** — always; migration is non-destructive but `library/` will rebuild
2. Open in Cocos Creator 3.8.x — `temp/` and `library/` reimport automatically
3. Check Console for deprecation warnings — fix all before proceeding
4. Review shaders — built-in Effect format may have minor renames; see `deprecated-apis.md`
5. Test procedural animation — if using legacy `AnimationClip`, verify it still imports correctly
6. (3.8.6+) Decide Box2D variant — TS / WASM / JSB (C++); JSB is recommended for native performance
7. (3.8.6+) Switch Spine version if upgrading — re-export Spine assets from Spine editor in target version
8. (3.8.6+) Consider enabling "Compress engine internal properties" — measure bundle size before/after

## Migration Checklist (v3.0 → v3.8.x)

If your project is still on v3.0:

1. **Update all `import` paths** — many modules reorganized between 3.0 and 3.5
2. **Review Material / Effect files** — format changed in 3.5; regenerate or hand-migrate
3. **Audit `cc.loader` usage** — should already be gone since v3.0, but verify no leftovers
4. **Migrate `cc.Class({...})` to TS classes** — if any remain
5. **Verify custom render pipeline usage** — early API changed; rebuild against 3.8 API
6. Run through the v3.7 → v3.8.x checklist above

## Migration Checklist (v2.x → v3.x)

This is a large migration. Use the **built-in v2.x → v3.x import tool** (`File → Import Cocos Creator 2.x project`) for assets, then manually migrate code:

1. Import assets via the tool — most art/audio/prefab resources convert automatically
2. **For each `.js` script** — convert to TypeScript, replace `cc.Class({...})` with `@ccclass` class, use ES module imports
3. Replace all `cc.loader.*` calls with `resources.*` or `assetManager.*`
4. Replace `cc.AudioEngine` with `AudioSource` component
5. Replace `node.x = 5` with `node.setPosition(5, node.position.y, node.position.z)`
6. Update event subscriptions — v3.x uses `EventTarget.on(event, cb, target)`
7. Update UI components — many were renamed; check `deprecated-apis.md`
8. Test on all target platforms — mini-game compatibility may differ
