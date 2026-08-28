---
paths:
  - "assets/**"
  - "**/*.ts"
  - "**/*.effect"
---

# Cocos Creator 3.x Code Rules

These rules apply to all TypeScript and Effect files in a Cocos Creator
3.x project (typically under `assets/scripts/` and `assets/effects/`).
They complement the engine-agnostic rules in `engine-code.md`; for hot-
path zero-allocation patterns see that file.

## Module / File Layout

- One component per file, file name = class name (`PlayerController.ts` → `class PlayerController`)
- Group related components in folders (`assets/scripts/player/`, `assets/scripts/ui/`)
- Effect files in `assets/effects/` — match folder to material category
- Import shared utilities from `assets/scripts/core/` — never re-implement

## Decorators (Required)

- Every `Component` class MUST have `@ccclass('ClassName')` — the
  string name is the runtime class ID and must be globally unique
- Every inspector-exposed field MUST have `@property({ type, tooltip })`
  — string shorthand is deprecated
- Use `@executeInEditMode` only when the component has editor-only
  `update()` / `onLoad()` work (gizmos, tool components). Guard the
  runtime side so editor doesn't pay for the same work
- Use `@requireComponent` only when the dependency is truly mandatory;
  overuse clutters the editor and the runtime
- Use `@disallowMultiple` for state containers and controllers
- Use `@menu('Category/Name')` to group in the Add Component menu

## Asset Loading

- `resources.load()` is for small config / JSON in `assets/resources/`
  only; never use for large assets in production
- Use `assetManager.loadBundle()` for cross-bundle content; cache the
  bundle reference, do not call `loadBundle` repeatedly with the same
  name
- Always pair `load()` / `instantiate()` with `releaseAsset()` /
  `bundle.releaseAll()` on the same lifecycle
- For streaming >1MB audio, set the asset's `LoadMode` to STREAMING
  in the import settings (not in code)

## Hot Update (Cocos-Specific)

- See [`docs/engine-reference/cocos/plugins/hot-update.md`](file:///workspace/docs/engine-reference/cocos/plugins/hot-update.md) — follow the manifest format and the
  reconnection helper
- NEVER ship executable code (new JS / TS source) via hot update on
  iOS / Android — App Store policy violation. Hot update assets only.
- Compare versions as semver tuples, not strings. The default
  string compare fails on `"1.10.0" < "1.9.0"`
- Set `AssetsManager.setMaxConcurrentTask(4)` for cellular networks;
  default of 32 saturates the radio

## Mini-Game Targets

- WeChat / ByteDance / Alipay each have different storage, file
  access, and audio APIs. Wrap in `assets/scripts/platform/` shims
  keyed off `sys.platform` — never scatter `wx.*` / `tt.*` / `my.*`
  calls
- File system access is restricted. Store player data via the
  platform's storage API (`wx.setStorageSync`), not raw file writes
- Audio playback: `audioEngine` works on mini-game but the platform
  may rate-limit. Test under sustained playback
- For multi-platform deploy, use Feature Cropping per platform preset
  to disable unused modules (e.g., 3D physics on 2D mini-game)

## Performance Hot Path Rules (Cocos-Specific)

- `node.setPosition()` is faster than `node.position = v3(...)` in
  3.8.6 (property setter path). 3.8.6 restored the property setter
  for ergonomics, but `setPosition` skips the change-detection
- Cache `getComponent()` results in `onLoad` / `start` — never call
  in `update`
- Use `tween().start()` for one-shot animations instead of
  `update` polling
- For batched custom shaders, declare `batching: true` in the
  Effect. Without it, the whole UI loses batching
- For UI, always use a `SpriteAtlas` — mixed-atlas sprites
  break batching

## Lifecycle

- `onLoad` — cache references, start asset preloads, register event
  listeners
- `start` — first-frame logic that depends on other components'
  `onLoad`
- `onEnable` / `onDisable` — subscribe / unsubscribe events
- `update` — per-frame, only when truly needed
- `onDestroy` — release references, listeners, assets; pair every
  `on()` with an `off()` somewhere

## Engine Version Awareness

Before writing any code that touches `cc.*` / engine API:

1. Read `docs/engine-reference/cocos/VERSION.md` for the pinned version
2. Check `docs/engine-reference/cocos/deprecated-apis.md` for removed APIs
3. Check `docs/engine-reference/cocos/breaking-changes.md` for version
   transitions
4. For subsystem work, read the relevant `docs/engine-reference/cocos/modules/*.md`
5. If an API is not in the reference docs, it may postdate the
   training data — use WebSearch to verify

If unsure between two APIs, prefer the one documented in the
reference files over what the model "remembers."

## Anti-Patterns to Flag

- `cc.Class({...})` in 3.x — use ES module TypeScript
- `cc.loader.loadRes()` — removed in 3.x
- `cc.eventManager` / `cc.systemEvent` — use `node.on()` or `input.on()`
- Calling `getComponent()` in `update`
- Subscribing events in `update` (leak per frame)
- Hard-coding platform-specific calls (`wx.*`, `tt.*`) without a shim
- Forgetting to `releaseAsset()` — memory growth on mini-game
- Mixing Cocos 2.x and 3.x APIs in the same project
- Hot-updating executable code on iOS / Android
