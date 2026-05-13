# Cocos Creator — Deprecated APIs

Last verified: 2026-06-27 | Engine: Cocos Creator 3.8.6

If an agent suggests any API in the "Deprecated" column, it MUST be replaced
with the "Use Instead" column.

## Resource Loading (Removed in v3.0)

| Deprecated | Use Instead | Since | Notes |
|------------|-------------|-------|-------|
| `cc.loader` (module) | `cc.assetManager` | v2.4 (deprecated) / v3.0 (removed) | Entire module replaced |
| `cc.loader.load()` | `assetManager.loadAny()` or `assetManager.loadRemote()` | v2.4 / v3.0 | Use specific bundle / resources APIs |
| `cc.loader.loadRes()` | `resources.load()` | v2.4 / v3.0 | Use `resources` for `assets/resources/` content |
| `cc.loader.loadResArray()` | `resources.load()` (pass array as first arg) | v2.4 / v3.0 | Merged into single load API |
| `cc.loader.loadResDir()` | `resources.loadDir()` | v2.4 / v3.0 | Callback no longer returns paths array |
| `cc.loader.getRes()` | `resources.get()` | v2.4 / v3.0 | Direct asset lookup |
| `cc.loader.release()` | `assetManager.releaseAsset()` or `resources.release()` | v2.4 / v3.0 | |
| `cc.loader.releaseAsset()` | `assetManager.releaseAsset()` | v2.4 / v3.0 | |
| `cc.loader.releaseRes()` | `resources.release()` | v2.4 / v3.0 | |
| `cc.loader.releaseResDir()` | `resources.release()` (with path) | v2.4 / v3.0 | |
| `cc.loader.releaseAll()` | `assetManager.releaseAll()` | v2.4 / v3.0 | |
| `cc.loader.getDependsRecursively()` | `assetManager.dependUtil.getDependsRecursively()` | v2.4 / v3.0 | |
| `cc.loader.onProgress` | Pass progress callback to load API | v2.4 / v3.0 | No global progress handler |
| `cc.loader.getXMLHttpRequest()` | `new XMLHttpRequest()` | v2.4 / v3.0 | Use native browser API |
| `cc.AssetLibrary` | `assetManager` | v1.10 / v3.0 | Long removed |
| `cc.url.raw()` | `assetManager.loadRemote()` or `@property` reference | v2.4 / v3.0 | No raw URL access |

## Class System (Removed in v3.0)

| Deprecated | Use Instead | Since | Notes |
|------------|-------------|-------|-------|
| `cc.Class({ extends: cc.Component, ... })` | ES module `class Foo extends Component` with `@ccclass` | v3.0 | JavaScript class syntax |
| `cc.Class({...}).properties = {...}` | `@property` decorators on class fields | v3.0 | |
| Global `cc.*` namespace access | ES module imports from `'cc'` | v3.0 | `import { Node, Component } from 'cc'` |
| `cc.Node.extend({...})` | TypeScript class extending `Node` (rarely needed) | v3.0 | Most Components extend `Component`, not `Node` |

## Node Property Access

| Deprecated | Use Instead | Since | Notes |
|------------|-------------|-------|-------|
| `node.x` (getter) | `node.position.x` | v3.0 | Removed in v3.0 |
| `node.x = 5` (setter) | `node.setPosition(5, y, z)` | v3.0 | Removed in v3.0 |
| `node.y` / `node.z` | `node.position.y` / `node.position.z` | v3.0 | |
| `node.setRotation()` (single-arg form) | `node.setRotationFromEuler()` for Euler angles | v3.0 | Disambiguated from quaternion form |
| `cc.p(x, y)` | `new Vec2(x, y)` or `v2(x, y)` | v3.0 | Helper removed |
| `cc.v2()` / `cc.v3()` / `cc.v4()` | `v2()` / `v3()` / `v4()` (named imports) | v3.0 | No `cc.` prefix |

> **3.8.6 Restoration**: `node.x`, `node.y`, `node.z` getter/setter shortcuts were
> re-added in v3.8.6. They internally call `getPosition()` / `setPosition()` so they
> are slower than direct Vec3 manipulation. Use them for readability in
> non-performance-critical code, but prefer `node.position.x` or `setPosition()` in
> hot loops.

## Audio System

| Deprecated | Use Instead | Since | Notes |
|------------|-------------|-------|-------|
| `cc.audioEngine.play(url, loop, volume)` | `AudioSource` component on scene node | v3.0 | URL-based playback removed |
| `cc.audioEngine.playEffect()` | `AudioSource` with 3D settings | v3.0 | |
| `cc.audioEngine.pause()` | `audioSource.pause()` | v3.0 | |
| `cc.audioEngine.resume()` | `audioSource.play()` | v3.0 | |
| `cc.audioEngine.stop()` | `audioSource.stop()` | v3.0 | |
| `cc.audioEngine.setVolume()` | `audioSource.volume = 0.5` | v3.0 | |

## UI Components

| Deprecated | Use Instead | Since | Notes |
|------------|-------------|-------|-------|
| `cc.Sprite` (no UITransform) | `cc.Sprite` + `UITransform` (required) | v3.0 | All UI nodes need UITransform |
| `cc.Label.setFontSize()` | `label.fontSize = 24` | v3.0 | Property-based API |
| `cc.RichText.setMaxWidth()` | `richText.maxWidth = 200` | v3.0 | Property-based API |
| `cc.Widget` (in pixels only) | `cc.Widget` with `AlignFlags` and relative offsets | v3.0 | Now supports both px and relative |
| `cc.Mask.Type.NONE` | Don't add `Mask` component | v3.0 | |
| `cc.view.setDesignResolutionSize()` (legacy signature) | Same API, but `cc.view` is now `view` import | v3.0 | `import { view } from 'cc'` |

## Animation

| Deprecated | Use Instead | Since | Notes |
|------------|-------------|-------|-------|
| `cc.Animation.play(name)` | `animation.play(name)` (component instance) | v3.0 | |
| `cc.AnimationClip.createWithSpriteFrames()` | Use editor to build clip from sprite frames | v3.0 | Removed from runtime API |
| `cc.tween(node).to(1, { x: 100 })` | `tween(node).to(1, { position: v3(100, 0, 0) })` | v3.0 | `x` no longer a top-level tween target |
| `ccTween` (global) | `tween` (named import) | v3.0 | |

## Editor / Settings

| Deprecated | Use Instead | Since | Notes |
|------------|-------------|-------|-------|
| `Editor.*` (in editor extensions) | `settings.querySettings()` for engine settings | v3.8 | For reading project settings at runtime |
| `Editor.log` / `Editor.warn` / `Editor.error` | `console.log` / `console.warn` / `console.error` | v3.5 | Use standard console in extensions |
| `cc.debug.setDisplayStats()` | `profiler.showStats()` / `profiler.hideStats()` | v3.0 | |

## Patterns (Not Just APIs)

| Deprecated Pattern | Use Instead | Why |
|--------------------|-------------|-----|
| `cc.Class({...})` JS class syntax | TypeScript class + `@ccclass` decorator | Type safety, IDE support, modern syntax |
| `cc.loader.loadRes()` for everything | `resources.load()` for configs, `assetManager` + bundles for content | Bundles support async, preloading, release |
| `resources.load()` for all assets | `assetManager.loadBundle()` + `bundle.load()` | `resources/` is special; bundles are the recommended path |
| String-based event names without constants | Typed event map or `const EVENT_HIT = 'hit'` constants | Refactor-friendly, IDE autocomplete |
| Subscribing in `update()` / `onLoad()` without unsubscribe | Pair in `onEnable` / `onDisable` or `onLoad` / `onDestroy` | Memory leak prevention |
| `setTimeout` / `setInterval` in Components | `this.schedule()` / `this.scheduleOnce()` | Auto-paused when component disabled |
| `getComponent()` in `update()` | Cache in `onLoad()` | Performance: reflection lookup every frame |
| Manual `node.x = a; node.y = b;` (3 calls) | `node.setPosition(a, b, z)` | Single call, avoids Vec3 rebuild |
| Hardcoded file paths in mini-game builds | `assetManager` API or `@property` references | Mini-game platforms restrict file access |
